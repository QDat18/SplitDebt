package com.splitdebt.api.ocr;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.net.URI;
import java.net.http.*;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.Semaphore;

@Service
public class ReceiptAdvancedService {
    private final ObjectMapper mapper;
    private final Semaphore slot = new Semaphore(1);
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(2)).build();
    public ReceiptAdvancedService(ObjectMapper mapper) {this.mapper=mapper;}
    public List<ReceiptAdvancedAnalysis.Candidate> scan(MultipartFile image,String mode) {
        if(image.isEmpty()||image.getSize()>8*1024*1024||!List.of("ocr","structure").contains(mode))throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Ảnh hoặc chế độ OCR không hợp lệ.");
        if(!slot.tryAcquire())throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,"OCR nâng cao đang bận.");
        try {
            var request=HttpRequest.newBuilder(URI.create("http://127.0.0.1:8002/recognize?mode="+mode))
                .header("Content-Type","application/octet-stream").timeout(Duration.ofSeconds(150))
                .POST(HttpRequest.BodyPublishers.ofByteArray(image.getBytes())).build();
            var response=http.send(request,HttpResponse.BodyHandlers.ofString());
            if(response.statusCode()!=200) {
                var status=switch(response.statusCode()) {case 400,413 -> HttpStatus.BAD_REQUEST;case 422 -> HttpStatus.UNPROCESSABLE_ENTITY;case 429 -> HttpStatus.TOO_MANY_REQUESTS;default -> HttpStatus.SERVICE_UNAVAILABLE;};
                throw new ResponseStatusException(status,"OCR local không nhận dạng được hoặc chưa sẵn sàng.");
            }
            if(response.body().length()>2_000_000)throw new IllegalArgumentException("Oversized OCR result");
            return ReceiptAdvancedAnalysis.analyze(mapper.readValue(response.body(),ReceiptAdvancedAnalysis.Payload.class));
        } catch(ResponseStatusException e){throw e;}
        catch(HttpTimeoutException e){throw new ResponseStatusException(HttpStatus.GATEWAY_TIMEOUT,"OCR nâng cao quá thời gian.");}
        catch(InterruptedException e){Thread.currentThread().interrupt();throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"OCR bị gián đoạn.");}
        catch(Exception e){throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Chưa kết nối được OCR local tại cổng 8002.");}
        finally{slot.release();}
    }
}
