package com.splitdebt.api.ocr;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.time.LocalDate;
import java.util.*;
import java.util.regex.*;

/** Conservative VND extraction. Unknown fields stay unknown until reviewed. */
public final class ReceiptParser {
    private ReceiptParser() {}
    public record Item(String name, long amount, Integer quantity, Long unitPrice) {}
    public record Result(String text, Long total, List<Item> items, List<String> warnings, String date, String merchant) {}
    private static final String M = "(?:\\d{1,9}[.,]\\d{1,3}[kK]|(?:\\d{1,3}(?:[., ]\\d{3})+|\\d{1,12})(?:[.,]0{1,2}|[.,]-)?(?:[kK]|\\s*(?:VND|VNĐ|đ|₫))?)";
    private static final Pattern MONEY = Pattern.compile("(?<![-+\\d.,])("+M+")\\s*$", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    private static final Pattern TABLE = Pattern.compile("^(.+?)\\s+(\\d{1,3})\\s*[xX×]?\\s+("+M+")\\s+("+M+")\\s*$", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    private static final Pattern TIMES = Pattern.compile("^(.+?)\\s+(\\d{1,3})\\s*[xX×]\\s*("+M+")\\s*(?:=\\s*("+M+"))?$", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    private static final Pattern DATE = Pattern.compile("(?<!\\d)(\\d{1,2})[/.-](\\d{1,2})[/.-](\\d{4}|\\d{2})(?!\\d)");
    private static final Pattern ISO = Pattern.compile("(?<!\\d)(\\d{4})[-/](\\d{2})[-/](\\d{2})(?!\\d)");
    static String normalized(String s) {
        if(s==null)return "";
        return Normalizer.normalize(Normalizer.normalize(s, Normalizer.Form.NFKC), Normalizer.Form.NFD).replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT).replace('đ','d');
    }
    static Long money(String s) {
        if (s == null) return null;
        String n = normalized(s).replaceAll("(?:vnd|d|₫)", "").strip();
        try {
            if(n.endsWith("k")) {
                String decimal=n.substring(0,n.length()-1).strip();
                if(!decimal.matches("\\d{1,9}(?:[.,]\\d{1,3})?"))return null;
                long v=new BigDecimal(decimal.replace(',','.')).multiply(BigDecimal.valueOf(1000)).longValueExact();
                return v>0&&v<=999_999_999_999L?v:null;
            }
            n=n.replaceFirst("(?:[.,]0{1,2}|[.,]-)$", "");
            if(!n.matches("(?:\\d{1,3}(?:\\.\\d{3})+|\\d{1,3}(?:,\\d{3})+|\\d{1,3}(?: \\d{3})+|\\d{1,12})"))return null;
            long v=Long.parseLong(n.replaceAll("[^0-9]", ""));
            return v>0&&v<=999_999_999_999L?v:null;
        }catch(ArithmeticException|NumberFormatException ex){return null;}
    }
    private static String dateOf(String line) {
        try {
            Matcher m=ISO.matcher(line); if(m.find()) return LocalDate.of(Integer.parseInt(m.group(1)),Integer.parseInt(m.group(2)),Integer.parseInt(m.group(3))).toString();
            m=DATE.matcher(line); if(m.find()) {
                int year=Integer.parseInt(m.group(3))+(m.group(3).length()==2?2000:0);
                return LocalDate.of(year,Integer.parseInt(m.group(2)),Integer.parseInt(m.group(1))).toString();
            }
        } catch (RuntimeException ignored) {} return null;
    }
    private static boolean ignored(String n) {
        return n.matches("^(?:tam tinh|cong tien hang|subtotal|sub total|thue|vat\\b|tax\\b|giam gia|chiet khau|khuyen mai|discount|phu phi|phi phuc vu|phi dich vu|service charge|tien khach|khach dua|tien mat|cash\\b|change\\b|tien thua|tien tra lai|chuyen khoan|ngay\\b|date\\b|time\\b|gio\\b|sdt\\b|dt\\b|tel\\b|phone\\b|hoa don|so hoa don|so hd\\b|so phieu|bill no|order no|ma don|invoice|receipt|dia chi|dc\\b|address|ma so|ma hd|mst\\b|hotline|tong\\b|total\\b|thanh toan|thanh tien|so luong|sl\\b|stt\\b|don gia|ten hang|ten mon|description|item\\b|cam on|thank|hen gap|wifi|website|www\\.|https?://|khach hang|thu ngan|nhan vien|nv\\b|cashier|table\\b|ban\\s*[:#]|so\\s*[:#]).*");
    }
    static String canonicalTotalLabel(String n) {
        // Latin OCR can drop complete Vietnamese vowel glyphs in thermal print.
        // Repair only known label words, never digits or merchandise descriptions.
        return n.replaceFirst("^(?:tng cong|tng cng|tong cng)(?=\\s|:|\\(|$)","tong cong")
                .replaceFirst("^(?:tng thanh toan|tng tin thanh toan)(?=\\s|:|\\(|$)","tong thanh toan");
    }
    private static int totalPriority(String n) {
        n=canonicalTotalLabel(n);
        if(n.matches(".*(?:tam tinh|subtotal|sub total|tien thue|tax|tien hang|so luong|tong sl|total qty|total quantity).*"))return 0;
        if(n.matches("^(?:tong (?:giam gia|chiet khau|khuyen mai|vat|thue)|total (?:discount|saving|cash|tender|change|paid))(?:\\b|$).*"))return 0;
        if(n.matches("^(?:tong thanh toan|tong tien thanh toan|tong so tien thanh toan|tien thanh toan|tong phai tra|can thanh toan|so tien phai tra|phai thanh toan|phai tra|grand total|net total|amount due|balance due|total due)(?:\\b|$).*"))return 2;
        if(n.matches("^(?:tong(?: cong| tien| so tien)?|total\\b|thanh toan|thanh tien)(?:\\s|:|\\(|$).*"))return 1;
        return 0;
    }
    public static Result parse(String text) {
        text=text==null?"":text;
        List<Item> items = new ArrayList<>(); List<String> warnings = new ArrayList<>();
        Map<Integer,Set<Long>> totalsByPriority=new TreeMap<>(); Set<String> dates = new LinkedHashSet<>();
        int pendingTotal=0; String merchant=null,pendingName="";
        String[] lines=text.replace('\u00a0',' ').replace('\u202f',' ').split("\\R");
        for(int index=0;index<lines.length;index++) {
            String raw=lines[index];
            String line = raw.strip().replaceAll("[\\t|]+", "  "); if (line.isEmpty()) continue;
            String n = normalized(line); String date = dateOf(line);
            if(date!=null){dates.add(date);pendingTotal=0;pendingName="";continue;}
            int priority=totalPriority(n); boolean total=priority>0;
            Matcher m = MONEY.matcher(line); boolean found=m.find();
            if(total||pendingTotal>0) {
                if(found&&(total||line.substring(0,m.start()).isBlank())) {
                    Long a=money(m.group(1));if(a!=null)totalsByPriority.computeIfAbsent(total?priority:pendingTotal,k->new LinkedHashSet<>()).add(a);
                    pendingTotal=0;pendingName="";continue;
                }
                if(total){pendingTotal=priority;pendingName="";continue;}pendingTotal=0;
            }
            if(ignored(n)){pendingName="";continue;}
            if(!pendingName.isEmpty()&&line.matches("[\\d., kKxX×=₫đĐVNDvnd -]+")) {
                line=pendingName+" "+line;m=MONEY.matcher(line);found=m.find();
            }
            pendingName="";
            String potentialName=line.replaceFirst("^\\d{1,3}[.)]\\s+(?=\\p{L})", "");
            if(!found&&potentialName.matches(".*\\p{L}.*")&&potentialName.length()<=160) {
                String next=index+1<lines.length?lines[index+1].strip():"";
                if(next.matches("[\\d., kKxX×=₫đĐVNDvnd -]+"))pendingName=potentialName;
                else if(merchant==null&&items.isEmpty()&&index<6&&line.length()<=100&&!line.matches(".*\\d.*"))merchant=line;
                continue;
            }
            if (!found || items.size()>=100) continue;
            Matcher t=TABLE.matcher(line), x=TIMES.matcher(line);
            String name; Long amount; Integer qty=null; Long unit=null;
            if (t.matches()) {
                name=t.group(1).strip(); int q=Integer.parseInt(t.group(2)); Long u=money(t.group(3)); amount=money(t.group(4));
                if(q>0 && u!=null && amount!=null && q*u==amount){qty=q;unit=u;}
                else warnings.add("Dòng chưa khớp số lượng × đơn giá: "+name);
            } else if(x.matches()) {
                name=x.group(1).strip(); int q=Integer.parseInt(x.group(2)); Long u=money(x.group(3)); amount=x.group(4)==null && u!=null ? Long.valueOf(q*u) : money(x.group(4));
                if(q>0 && u!=null && amount!=null && q*u==amount && amount<=999_999_999_999L){qty=q;unit=u;}
                else warnings.add("Dòng chưa khớp số lượng × đơn giá: "+name);
            } else { name=line.substring(0,m.start()).strip().replaceAll("[:|]+$", "").strip(); amount=money(m.group(1)); }
            name=name.replaceFirst("^\\d{1,3}[.)]\\s+(?=\\p{L})", "");
            if (amount!=null && amount>0 && amount<=999_999_999_999L && !name.isEmpty() && name.matches(".*\\p{L}.*")) items.add(new Item(name.length()>160?name.substring(0,160):name,amount,qty,unit));
        }
        Set<Long> totals=totalsByPriority.isEmpty()?Set.of():totalsByPriority.get(Collections.max(totalsByPriority.keySet()));
        Long total=totals.size()==1?totals.iterator().next():null;
        if(total==null) warnings.add(totals.isEmpty()?"Không tìm thấy tổng tiền rõ ràng; hãy đối chiếu ảnh.":"Có nhiều tổng tiền khác nhau; hãy đối chiếu ảnh.");
        if(total!=null&&!items.isEmpty()&&items.stream().mapToLong(Item::amount).sum()!=total) warnings.add("Tổng tiền hàng khác tổng hóa đơn (thuế, giảm giá hoặc OCR sai). Kiểm tra trước khi lưu.");
        if(items.stream().anyMatch(i->i.quantity()==null)) warnings.add("Có dòng không xác định được số lượng/đơn giá; cần xác nhận.");
        if(dates.size()!=1) warnings.add("Ngày chi chưa rõ; hãy chọn ngày đúng.");
        if(items.isEmpty())warnings.add("Chưa đọc được các món hàng; hãy kiểm tra ảnh hoặc nhập thủ công.");
        if(normalized(text).matches("(?s).*(?:\\busd\\b|\\beur\\b|\\bthb\\b|[$€฿]).*"))warnings.add("Phát hiện ký hiệu ngoại tệ; trình nhận dạng hiện phân tích tiền VND, cần kiểm tra đơn vị tiền.");
        return new Result(text,total,List.copyOf(items),List.copyOf(warnings),dates.size()==1?dates.iterator().next():null,merchant);
    }
}
