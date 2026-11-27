import com.splitdebt.api.ocr.*;
import java.util.*;
public class AdvancedCheck {
 static int n;
 static void check(String name,boolean ok){if(!ok)throw new AssertionError(name);n++;System.out.println("PASS "+name);}
 static final List<String> header=List.of("Tên hàng","SL","Đơn giá","Thành tiền");
 static final List<String> row=List.of("Cơm gà","2","45.000","90.000");
 static List<ReceiptAdvancedAnalysis.Candidate> run(String total,List<List<List<String>>> tables){return ReceiptAdvancedAnalysis.analyze(new ReceiptAdvancedAnalysis.Payload("Ngày 26/11/2026\nCơm gà 2 45.000 90.000\nTổng thanh toán "+total,List.of(),tables,"structure"));}
 public static void main(String[] args){
   var r=run("90.000",List.of(List.of(header,row)));check("table candidate preserved independently",r.size()==2&&r.get(1).result().items().getFirst().quantity()==2&&r.get(1).result().total()==90000);
   check("reordered columns",run("90.000",List.of(List.of(List.of("SL","Thành tiền","Tên hàng","Đơn giá"),List.of("2","90.000","Cơm gà","45.000")))).get(1).result().items().getFirst().unitPrice()==45000);
   check("invalid arithmetic rejected",run("90.000",List.of(List.of(header,List.of("Cơm gà","2","45.000","99.000")))).size()==1);
   check("multiple tables not combined",run("90.000",List.of(List.of(header,row),List.of(header,row))).size()==1);
   check("mismatch total warns",!run("99.000",List.of(List.of(header,row))).get(1).result().warnings().isEmpty());
   check("missing header rejected",run("90.000",List.of(List.of(row,row))).size()==1);
   check("missing qty rejected",run("90.000",List.of(List.of(header,List.of("Cơm gà","","45.000","90.000")))).size()==1);
   check("ragged rows rejected",run("90.000",List.of(List.of(header,List.of("Cơm gà","2","45.000")))).size()==1);
   check("table footer skipped",run("90.000",List.of(List.of(header,row,List.of("Tổng cộng","","","90.000")))).get(1).result().items().size()==1);
   check("uncertain fallback",ReceiptAdvancedAnalysis.needsReview(run("90.000",List.of()).getFirst().result()));
   System.out.println(n+" passed");
 }
}
