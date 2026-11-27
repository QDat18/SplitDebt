package com.splitdebt.api.ocr;

import java.util.*;

/** Uses actual recognized table cells, not guessed per-word coordinates. */
public final class ReceiptAdvancedAnalysis {
    private ReceiptAdvancedAnalysis() {}
    public record Payload(String text, List<ReceiptLayoutAnalyzer.Word> words,
                          List<List<List<String>>> tables, String engine) {}
    public record Candidate(String source, ReceiptParser.Result result) {}
    private static String role(String text) {
        if (text == null) return "";
        return switch (ReceiptParser.normalized(text).replaceAll("[^a-z0-9 ]", " ").replaceAll(" +", " ").strip()) {
            case "ten hang", "ten hh", "ten mon", "ten san pham", "san pham", "mat hang", "hang hoa", "dien giai", "description", "item", "product", "name" -> "name";
            case "sl", "so luong", "qty", "quantity" -> "qty";
            case "don gia", "d gia", "dg", "unit price", "price", "gia ban" -> "unit";
            case "thanh tien", "t tien", "ttien", "so tien", "amount", "line total", "total", "tong tien" -> "amount";
            default -> "";
        };
    }
    public static boolean needsReview(ReceiptParser.Result r) {
        if (r == null || r.total() == null || r.date() == null || r.items().isEmpty() || !r.warnings().isEmpty()) return true;
        return r.items().stream().anyMatch(i -> i.quantity() == null || i.unitPrice() == null || i.quantity() * i.unitPrice() != i.amount())
                || r.items().stream().mapToLong(ReceiptParser.Item::amount).sum() != r.total();
    }
    private static List<ReceiptParser.Item> tableItems(List<List<String>> table) {
        if (table == null || table.size() < 2 || table.size() > 101) return List.of();
        var header = table.getFirst();
        if (header == null || header.size() < 2 || header.size() > 12) return List.of();
        Map<String,Integer> columns = new HashMap<>();
        for (int i=0;i<header.size();i++) {
            String r=role(header.get(i));
            if (!r.isEmpty() && columns.put(r,i)!=null) return List.of();
        }
        if (!columns.containsKey("name")||!columns.containsKey("amount")) return List.of();
        var items=new ArrayList<ReceiptParser.Item>();
        for (var row:table.subList(1,table.size())) {
            if(row==null || row.size()!=header.size() || row.stream().anyMatch(Objects::isNull)) return List.of();
            String name=row.get(columns.get("name")).strip();
            String norm=ReceiptParser.canonicalTotalLabel(ReceiptParser.normalized(name));
            if(norm.matches("^(tong|tam tinh|total|subtotal|vat|thue|giam gia|discount|tax|phu phi)(\\b|$).*")) {
                // A footer may be present only as the last row, never treated as merchandise.
                if(row!=table.getLast())return List.of();
                break;
            }
            if(name.isBlank()||name.length()>160||!name.matches(".*\\p{L}.*"))return List.of();
            Integer q=null;
            if(columns.containsKey("qty")) {
                try{q=Integer.valueOf(row.get(columns.get("qty")).strip());}catch(NumberFormatException e){return List.of();}
                if(q<=0||q>999)return List.of();
            }
            Long u=columns.containsKey("unit")?ReceiptParser.money(row.get(columns.get("unit"))):null;
            Long a=ReceiptParser.money(row.get(columns.get("amount")));
            if(a==null||(columns.containsKey("unit")&&u==null)||(q!=null&&u!=null&&q*u!=a))return List.of();
            items.add(new ReceiptParser.Item(name,a,q,u));
        }
        return items;
    }
    public static List<Candidate> analyze(Payload p) {
        if(p==null||p.text()==null||p.text().isBlank()||p.text().length()>24000||p.words()==null||p.words().size()>1500)throw new IllegalArgumentException("Invalid OCR payload");
        var base=ReceiptLayoutAnalyzer.analyze(p.text(),p.words());
        var candidates=new ArrayList<Candidate>();
        candidates.add(new Candidate("structure".equals(p.engine()) ? "PP-StructureV3 — tọa độ" : "PaddleOCR — tọa độ",base));
        if(p.tables()!=null&&p.tables().size()==1) {
            var items=tableItems(p.tables().getFirst());
            if(!items.isEmpty()) {
                var warnings=new ArrayList<String>();
                if(base.total()==null)warnings.add("Chưa xác định tổng thanh toán trên ảnh.");
                else if(items.stream().mapToLong(ReceiptParser.Item::amount).sum()!=base.total())warnings.add("Tiền hàng khác tổng thanh toán; kiểm tra thuế, giảm giá và các dòng thiếu.");
                if(base.date()==null)warnings.add("Chưa xác định ngày chi.");
                if(items.stream().anyMatch(i->i.quantity()==null||i.unitPrice()==null))warnings.add("Bảng thiếu cột số lượng hoặc đơn giá; cần xác nhận từng món.");
                if(!items.equals(base.items()))warnings.add("Kết quả nhận dạng bảng khác kết quả theo tọa độ; đối chiếu ảnh gốc.");
                if(p.words().stream().anyMatch(w->w!=null&&w.confidence()!=null&&w.confidence()<65))warnings.add("Một số vùng OCR có độ tin cậy thấp.");
                candidates.add(new Candidate("PP-StructureV3 — ô bảng",new ReceiptParser.Result(p.text(),base.total(),List.copyOf(items),List.copyOf(warnings),base.date(),base.merchant())));
            }
        }
        return candidates;
    }
}
