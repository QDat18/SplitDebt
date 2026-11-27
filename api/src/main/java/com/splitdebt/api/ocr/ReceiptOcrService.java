package com.splitdebt.api.ocr;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import java.awt.Color;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.*;
import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.*;

@Service
public class ReceiptOcrService {
    private final ObjectMapper mapper;
    private final Semaphore slots = new Semaphore(2);
    @Value("${OCR_TESSERACT_PATH:tesseract}") private String executable;
    @Value("${OCR_LANG:vie+eng}") private String language;
    @Value("${OCR_VISION_API_KEY:}") private String visionKey;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(8)).build();
    public ReceiptOcrService(ObjectMapper mapper) { this.mapper = mapper; }
    public boolean handwritingAvailable() { return !visionKey.isBlank(); }
    public ReceiptParser.Result scan(MultipartFile file, boolean handwriting) {
        if (file.isEmpty() || file.getSize() > 8 * 1024 * 1024) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Chọn ảnh JPEG/PNG tối đa 8 MB.");
        if (handwriting && !handwritingAvailable()) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"OCR viết tay chưa được cấu hình.");
        if (!slots.tryAcquire()) throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,"Đang có nhiều lượt quét, vui lòng thử lại.");
        try {
            byte[] bytes = file.getBytes();
            validateImage(bytes);
            ReceiptParser.Result result=handwriting?ReceiptParser.parse(cloud(bytes)):local(bytes);
            if(result.text().isBlank())throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,"Không đọc được chữ; hãy chụp rõ hơn hoặc nhập tay.");
            return result;
        } catch (ResponseStatusException e) { throw e; }
        catch (InterruptedException e) { Thread.currentThread().interrupt(); throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Lượt quét bị gián đoạn."); }
        catch (Exception e) { throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Không thể quét hóa đơn. Kiểm tra cấu hình OCR hoặc nhập tay."); }
        finally { slots.release(); }
    }
    private void validateImage(byte[] bytes) throws IOException {
        try (var input = ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
            if (input == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Ảnh không hợp lệ.");
            Iterator<ImageReader> readers = ImageIO.getImageReaders(input);
            if (!readers.hasNext()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Ảnh không hợp lệ.");
            ImageReader reader = readers.next();
            try {
                reader.setInput(input,true,true);
                if (!Set.of("jpeg","png").contains(reader.getFormatName().toLowerCase(Locale.ROOT)) || (long)reader.getWidth(0)*reader.getHeight(0)>16_000_000L) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Chỉ hỗ trợ JPEG/PNG tối đa 16 megapixel.");
            } finally { reader.dispose(); }
        }
    }
    private ReceiptParser.Result local(byte[] bytes) throws IOException, InterruptedException {
        var candidates=new ArrayList<ReceiptParser.Result>();
        long deadline=System.nanoTime()+TimeUnit.SECONDS.toNanos(36);
        // Compare the original with a gently normalized image. Never trust one segmentation
        // mode for all layouts: psm 4 handles columns; psm 6 handles compact POS receipts.
        candidates.add(localPass(bytes,4,deadline));
        try {candidates.add(localPass(prepare(bytes),6,deadline));}
        catch(IOException|ResponseStatusException ignored) {
            // A usable first pass survives a failed enhancement or a time-limited retry.
        }
        var best=candidates.stream().max(Comparator.comparingInt(ReceiptOcrService::quality)).orElseThrow();
        var warnings=new ArrayList<>(best.warnings());
        var totals=candidates.stream().map(ReceiptParser.Result::total).filter(Objects::nonNull).distinct().toList();
        Long total=best.total();
        if(totals.size()>1){total=null;warnings.add("Các lượt OCR đọc tổng tiền khác nhau; hãy xác nhận tổng tiền trên ảnh.");}
        return new ReceiptParser.Result(best.text(),total,best.items(),List.copyOf(warnings),best.date(),best.merchant());
    }
    private static int quality(ReceiptParser.Result result) {
        int score=(result.total()!=null?80:0)+(result.date()!=null?10:0)+Math.min(30,result.items().size()*3);
        if(result.total()!=null&&!result.items().isEmpty()&&result.items().stream().mapToLong(ReceiptParser.Item::amount).sum()==result.total())score+=60;
        score+=(int)result.items().stream().filter(i->i.quantity()!=null&&i.unitPrice()!=null&&i.quantity()*i.unitPrice()==i.amount()).count()*5;
        return score-Math.min(25,result.warnings().size());
    }
    private static byte[] prepare(byte[] bytes) throws IOException {
        BufferedImage source=ImageIO.read(new ByteArrayInputStream(bytes));
        if(source==null)throw new IOException("Invalid image");
        double scale=Math.min(2.5,Math.max(1,1200.0/source.getWidth()));
        scale=Math.min(scale,Math.min(6000.0/Math.max(source.getWidth(),source.getHeight()),Math.sqrt(12_000_000.0/((long)source.getWidth()*source.getHeight()))));
        int width=Math.max(1,(int)Math.round(source.getWidth()*scale)),height=Math.max(1,(int)Math.round(source.getHeight()*scale));
        BufferedImage image=new BufferedImage(width,height,BufferedImage.TYPE_BYTE_GRAY);
        var graphics=image.createGraphics();
        try {
            graphics.setColor(Color.WHITE);graphics.fillRect(0,0,width,height);
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION,RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.drawImage(source,0,0,width,height,null);
        } finally {graphics.dispose();}
        // Stretch only the outer 1% of the histogram, keeping faint thermal text intact.
        int[] histogram=new int[256];var raster=image.getRaster();
        for(int y=0;y<height;y++)for(int x=0;x<width;x++)histogram[raster.getSample(x,y,0)]++;
        int limit=Math.max(1,width*height/100),low=0,high=255,count=0;
        while(low<254&&count+histogram[low]<limit)count+=histogram[low++];
        count=0;while(high>low+1&&count+histogram[high]<limit)count+=histogram[high--];
        if(high-low>20)for(int y=0;y<height;y++)for(int x=0;x<width;x++)raster.setSample(x,y,0,Math.max(0,Math.min(255,(raster.getSample(x,y,0)-low)*255/(high-low))));
        var output=new ByteArrayOutputStream();ImageIO.write(image,"png",output);return output.toByteArray();
    }
    private ReceiptParser.Result localPass(byte[] bytes,int segmentation,long deadline) throws IOException, InterruptedException {
        Path input = Files.createTempFile("splitdebt-receipt-", ".img");
        Path output = null; Process process = null;
        try {
            output = Files.createTempFile("splitdebt-ocr-", ".txt");
            Files.write(input,bytes);
            process = new ProcessBuilder(executable,input.toString(),"stdout","-l",language,"--psm",Integer.toString(segmentation),"tsv")
                    .redirectOutput(output.toFile()).redirectError(ProcessBuilder.Redirect.DISCARD).start();
            if(!process.waitFor(Math.max(1,deadline-System.nanoTime()),TimeUnit.NANOSECONDS))throw new ResponseStatusException(HttpStatus.GATEWAY_TIMEOUT,"Quét quá thời gian; hãy thử ảnh nhỏ hơn.");
            if (process.exitValue()!=0) throw new IOException("OCR failed");
            try(Reader reader=Files.newBufferedReader(output,StandardCharsets.UTF_8)) {
                char[] buffer=new char[2_000_001];int count=0,n;
                while(count<buffer.length&&(n=reader.read(buffer,count,buffer.length-count))>=0)count+=n;
                if(count>2_000_000)throw new IOException("Oversized OCR output");
                return parseTsv(new String(buffer,0,count));
            }
        } finally {
            if(process!=null && process.isAlive()) { process.destroyForcibly(); process.waitFor(2,TimeUnit.SECONDS); }
            Files.deleteIfExists(input); if(output!=null) Files.deleteIfExists(output);
        }
    }
    static ReceiptParser.Result parseTsv(String tsv) {
        var words=new ArrayList<ReceiptLayoutAnalyzer.Word>();
        Map<String,List<String>> lines=new LinkedHashMap<>();
        for(String line:tsv.split("\\R")) {
            String[] fields=line.split("\\t",12);
            if(fields.length!=12||!"5".equals(fields[0])||fields[11].isBlank())continue;
            try {
                double x=Double.parseDouble(fields[6]),y=Double.parseDouble(fields[7]);
                double width=Double.parseDouble(fields[8]),height=Double.parseDouble(fields[9]),confidence=Double.parseDouble(fields[10]);
                var word=new ReceiptLayoutAnalyzer.Word(fields[11].strip(),x,y,x+width,y+height,confidence);
                if(!word.valid())continue;
                words.add(word);lines.computeIfAbsent(String.join(":",Arrays.copyOfRange(fields,1,5)),k->new ArrayList<>()).add(word.text());
                if(words.size()>=1500)break;
            }catch(NumberFormatException ignored){}
        }
        String text=String.join("\n",lines.values().stream().map(parts->String.join(" ",parts)).toList());
        if(text.length()>24000)text=text.substring(0,24000);
        return ReceiptLayoutAnalyzer.analyze(text,words);
    }
    private String cloud(byte[] bytes) throws IOException, InterruptedException {
        String body=mapper.writeValueAsString(Map.of("requests",List.of(Map.of("image",Map.of("content",Base64.getEncoder().encodeToString(bytes)),"features",List.of(Map.of("type","DOCUMENT_TEXT_DETECTION"))))));
        HttpRequest request=HttpRequest.newBuilder(URI.create("https://vision.googleapis.com/v1/images:annotate"))
                .header("X-Goog-Api-Key",visionKey).header("Content-Type","application/json").timeout(Duration.ofSeconds(22)).POST(HttpRequest.BodyPublishers.ofString(body)).build();
        var response=http.send(request,HttpResponse.BodyHandlers.ofString());
        if(response.statusCode()!=200) throw new IOException("Cloud OCR failed");
        var result=mapper.readTree(response.body()).path("responses").path(0);
        if(result.has("error")) throw new IOException("Cloud OCR failed");
        String text=result.path("fullTextAnnotation").path("text").asText("");
        return text.length()>24000?text.substring(0,24000):text;
    }
}
