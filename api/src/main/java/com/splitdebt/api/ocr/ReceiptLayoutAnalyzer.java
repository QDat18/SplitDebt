package com.splitdebt.api.ocr;

import java.util.*;
import java.util.regex.Pattern;

/** Geometry-aware VND extraction. No learned model or assumed column order. */
public final class ReceiptLayoutAnalyzer {
    private ReceiptLayoutAnalyzer() {}
    public record Word(String text, double x0, double y0, double x1, double y1, Double confidence) {
        double x() { return (x0+x1)/2; }
        double y() { return (y0+y1)/2; }
        double h() { return y1-y0; }
        boolean valid() { return text!=null && !text.isBlank() && text.length()<=200 &&
            Double.isFinite(x0)&&Double.isFinite(x1)&&Double.isFinite(y0)&&Double.isFinite(y1)&&
            x0>=0&&y0>=0&&x1>x0&&y1>y0&&x1<=20000&&y1<=20000&&
            (confidence==null||Double.isFinite(confidence)&&confidence>=0&&confidence<=100); }
    }
    private enum Role { NAME, QTY, UNIT, AMOUNT, IGNORE }
    private record Column(Role role,double x) {}
    private record Header(int row, List<Column> columns) {}
    private static final Pattern FOOTER=Pattern.compile("^(?:tong(?:\\b|$)|tam tinh|subtotal|sub total|grand total|total\\b|can thanh toan|phai tra|amount due|thanh toan|vat\\b|thue|tax\\b|giam gia|discount|phu phi|service charge|tien khach|tien mat|tien thua|cash\\b|change\\b|cam on|thank).*",Pattern.CASE_INSENSITIVE);
    private static String norm(String s) {return ReceiptParser.canonicalTotalLabel(ReceiptParser.normalized(s).replaceAll("[^a-z0-9 ]", " ").replaceAll(" +"," ").strip());}
    private static String join(List<Word> words) {return String.join(" ",words.stream().map(Word::text).toList());}
    private static double median(List<Double> values) {var v=values.stream().sorted().toList();return v.get(v.size()/2);}
    // Estimate a small common tilt using widely separated words that align after projection.
    // Limit candidate pairs so long receipts do not incur unbounded work.
    private static double tilt(List<Word> input,double typical) {
        var sorted=input.stream().sorted(Comparator.comparingDouble(Word::y).thenComparingDouble(Word::x)).toList();
        int step=Math.max(1,(sorted.size()+239)/240);var sample=new ArrayList<Word>();
        for(int i=0;i<sorted.size();i+=step)sample.add(sorted.get(i));
        int[] votes=new int[21];
        for(int i=0;i<sample.size();i++)for(int j=i+1;j<sample.size();j++) {
            var a=sample.get(i);var b=sample.get(j);double dx=b.x()-a.x(),dy=b.y()-a.y();
            if(Math.abs(dx)<typical*3 || Math.abs(dy)>Math.abs(dx)*.10+typical*.28)continue;
            for(int k=0;k<votes.length;k++)if(Math.abs(dy-(k-10)*.01*dx)<typical*.28)votes[k]++;
        }
        int best=10;for(int k=0;k<votes.length;k++)if(votes[k]>votes[best] || votes[k]==votes[best]&&Math.abs(k-10)<Math.abs(best-10))best=k;
        return votes[best]>=5 && votes[best]>votes[10]*1.2 ? (best-10)*.01 : 0;
    }
    private static double rowY(Word w,double tilt){return w.y()-w.x()*tilt;}
    static List<List<Word>> rows(List<Word> words) {
        if(words.isEmpty()) return List.of();
        double typical=median(words.stream().map(Word::h).toList());
        double tilt=tilt(words,typical);
        var sorted=words.stream().sorted(Comparator.comparingDouble((Word w)->rowY(w,tilt)).thenComparingDouble(Word::x)).toList();
        List<List<Word>> rows=new ArrayList<>();
        for(var w:sorted) {
            List<Word> last=rows.isEmpty()?null:rows.getLast();
            if(last==null || Math.abs(rowY(w,tilt)-median(last.stream().map(v->rowY(v,tilt)).toList()))>typical*.48) {
                last=new ArrayList<>();rows.add(last);
            }
            last.add(w);
        }
        for(var r:rows) r.sort(Comparator.comparingDouble(Word::x0));
        return rows;
    }
    private static Role label(String n) { return switch(n) {
        case "ten hang","ten hh","ten mon","ten san pham","san pham","mat hang","hang hoa","noi dung","dien giai","description","item","items","product","name" -> Role.NAME;
        case "sl","so luong","qty","quantity" -> Role.QTY;
        case "don gia","d gia","dg","unit price","price","gia","gia ban" -> Role.UNIT;
        case "thanh tien","t tien","ttien","so tien","amount","line total","total","tong tien" -> Role.AMOUNT;
        case "stt","no","ma hang","sku","dvt","don vi","unit","discount","giam gia" -> Role.IGNORE;
        default -> null;
    };}
    private static Header header(List<List<Word>> rows) {
        for(int r=0;r<Math.min(30,rows.size());r++) {
            var words=rows.get(r);var columns=new ArrayList<Column>();
            for(int i=0;i<words.size();) {
                Role role=null;int end=i;
                for(int j=Math.min(i+2,words.size()-1);j>=i;j--) {
                    // Do not combine distant tokens into a multiword header.
                    boolean close=true;
                    for(int k=i+1;k<=j;k++) if(words.get(k).x0()-words.get(k-1).x1()>Math.max(words.get(k).h(),words.get(k-1).h())*1.5) close=false;
                    if(!close)continue;
                    role=label(norm(join(words.subList(i,j+1))));if(role!=null){end=j;break;}
                }
                if(role!=null){columns.add(new Column(role,(words.get(i).x0()+words.get(end).x1())/2));i=end+1;}else i++;
            }
            var roles=columns.stream().map(Column::role).toList();
            if(roles.contains(Role.NAME)&&roles.contains(Role.AMOUNT)&&roles.stream().filter(x->x==Role.AMOUNT).count()==1&&roles.stream().filter(x->x==Role.NAME).count()==1&&roles.stream().filter(x->x==Role.QTY).count()<=1&&roles.stream().filter(x->x==Role.UNIT).count()<=1) return new Header(r,columns);
        }return null;
    }
    private static Role role(Word word,List<Column> cols) {
        // Name text can extend toward the next numeric column; use nearest header center for numbers.
        return cols.stream().min(Comparator.comparingDouble(c->Math.abs(c.x()-word.x()))).orElseThrow().role();
    }
    private static String cell(Map<Role,List<Word>> cells,Role r) {return join(cells.getOrDefault(r,List.of()));}
    private static Long amount(String s) {return ReceiptParser.money(s);}
    private static Integer quantity(String s) {try {int n=Integer.parseInt(s.strip());return n>0&&n<=999?n:null;}catch(RuntimeException e){return null;}}
    private static boolean low(List<Word> words) {return words.stream().anyMatch(w->w.confidence()!=null && w.confidence()>=0 && w.confidence()<65);}
    public static ReceiptParser.Result analyze(String text,List<Word> input) {
        if(input==null||input.isEmpty()) return fallback(text,"Không có tọa độ OCR; đang phân tích văn bản, cần kiểm tra từng dòng.");
        var valid=input.stream().filter(Objects::nonNull).filter(Word::valid).limit(1500).toList();
        if(valid.size()!=input.size())return fallback(text,"Tọa độ OCR thiếu hoặc không hợp lệ; cần kiểm tra từng dòng.");
        var rows=rows(valid);String rebuilt=String.join("\n",rows.stream().map(ReceiptLayoutAnalyzer::join).toList());
        var base=ReceiptParser.parse(rebuilt);var header=header(rows);
        if(header==null)return fallbackWithRaw(text,rebuilt,"Không xác định được tiêu đề cột; phân tích theo các dòng tọa độ, chưa xác nhận cấu trúc bảng.");
        var warnings=new ArrayList<String>();var items=new ArrayList<ReceiptParser.Item>();
        String pending="";double pendingY=0;boolean pendingLow=false;boolean footer=false;
        double typical=median(valid.stream().map(Word::h).toList());
        for(int i=header.row()+1;i<rows.size()&&items.size()<100;i++) {
            var row=rows.get(i);String raw=join(row);String n=norm(raw);
            if(FOOTER.matcher(n).matches()){footer=true;break;}
            Map<Role,List<Word>> cells=new EnumMap<>(Role.class);
            for(var w:row) {
                Role assigned=role(w,header.columns());
                // Preserve a long name crossing a center boundary only while no numeric cell has started.
                if(assigned!=Role.NAME && assigned!=Role.IGNORE && !w.text().matches(".*\\d.*")
                    && cells.containsKey(Role.NAME) && !cells.containsKey(Role.QTY) && !cells.containsKey(Role.UNIT) && !cells.containsKey(Role.AMOUNT)) {
                    var prev=cells.get(Role.NAME).getLast();
                    if(w.x0()-prev.x1()<=typical*1.2)assigned=Role.NAME;
                }
                cells.computeIfAbsent(assigned,k->new ArrayList<>()).add(w);
            }
            String name=cell(cells,Role.NAME).strip(), qText=cell(cells,Role.QTY), uText=cell(cells,Role.UNIT), aText=cell(cells,Role.AMOUNT);
            double y=median(row.stream().map(Word::y).toList());
            if(!pending.isEmpty()&&y-pendingY>typical*2.4){warnings.add("Dòng tên hàng chưa ghép được: "+pending);pending="";pendingLow=false;}
            if(aText.isBlank()&&qText.isBlank()&&uText.isBlank()&&!name.isBlank()){
                pending=(pending+" "+name).strip();pendingY=y;pendingLow|=low(row);continue;
            }
            // A wrapped name can be continued by a row containing numbers only.
            if(!pending.isEmpty()){name=(pending+" "+name).strip();pending="";}
            if(name.isBlank()||!name.matches(".*\\p{L}.*")){warnings.add("Dòng chưa xác định tên hàng: "+raw);pendingLow=false;continue;}
            Long a=amount(aText), u=amount(uText);Integer q=quantity(qText);
            if(a==null){warnings.add("Không đọc được thành tiền của: "+name+" ("+raw+")");pendingLow=false;continue;}
            if(q==null||u==null)warnings.add("Thiếu số lượng hoặc đơn giá: "+name);
            else if(q*u!=a)warnings.add("Sai lệch số lượng × đơn giá ở: "+name+"; giữ nguyên số đọc được.");
            if(low(row)||pendingLow)warnings.add("Độ tin cậy OCR thấp ở: "+name+"; đối chiếu ảnh.");
            pendingLow=false;
            items.add(new ReceiptParser.Item(name.length()>160?name.substring(0,160):name,a,q,u));
        }
        if(!pending.isBlank())warnings.add("Dòng tên hàng chưa ghép được: "+pending);
        if(!footer)warnings.add("Không xác định được vùng cuối bảng; kiểm tra danh sách hàng.");
        if(items.isEmpty())return fallbackWithRaw(text,rebuilt,"Có tiêu đề cột nhưng chưa ghép được hàng; kiểm tra dữ liệu thủ công.");
        if(base.total()==null)warnings.add("Tổng thanh toán chưa rõ hoặc có nhiều giá trị.");
        if(base.date()==null)warnings.add("Ngày chi chưa rõ; hãy chọn ngày đúng.");
        if(rows.stream().anyMatch(row->(FOOTER.matcher(norm(join(row))).matches()||norm(join(row)).startsWith("ngay "))&&low(row)))warnings.add("Ngày hoặc vùng tổng tiền có chữ OCR độ tin cậy thấp; đối chiếu ảnh gốc.");
        if(base.total()!=null&&items.stream().mapToLong(ReceiptParser.Item::amount).sum()!=base.total())warnings.add("Tổng dòng hàng khác tổng thanh toán: kiểm tra thuế, giảm giá, phụ phí hoặc lỗi OCR.");
        return new ReceiptParser.Result(text,base.total(),List.copyOf(items),List.copyOf(warnings),base.date(),base.merchant());
    }
    private static ReceiptParser.Result fallback(String text,String warning){return fallbackWithRaw(text,text,warning);}
    private static ReceiptParser.Result fallbackWithRaw(String text,String rebuilt,String warning){
        var p=ReceiptParser.parse(rebuilt);var w=new ArrayList<>(p.warnings());w.addFirst(warning);
        return new ReceiptParser.Result(text,p.total(),p.items(),List.copyOf(w),p.date(),p.merchant());
    }
}
