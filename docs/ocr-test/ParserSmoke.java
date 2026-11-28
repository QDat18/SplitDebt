import com.splitdebt.api.ocr.ReceiptParser;
import java.nio.file.*;
public class ParserSmoke {
 static void check(boolean v,String n){if(!v)throw new AssertionError(n);System.out.println("PASS "+n);}
 public static void main(String[] args)throws Exception{
 var a=ReceiptParser.parse("Cơm gà 45.000\nTrà đá 5.000\nTổng cộng 50.000 đ");check(a.total()==50000&&a.items().size()==2&&a.items().getFirst().quantity()==null&&!a.warnings().isEmpty(),"standard printed receipt");
 check(ReceiptParser.parse("Cơm 40.000\nNước 10.000").total()==null,"no total: do not guess");
 var b=ReceiptParser.parse("Phở 50,000\nVAT 5,000\nTổng thanh toán:\n55,000 VND");check(b.total()==55000&&b.items().size()==1&&!b.warnings().isEmpty(),"tax mismatch warning and next-line total");
 check(ReceiptParser.parse("Tổng cộng 40.000\nTổng tiền 50.000").total()==null,"ambiguous totals");
 var c=ReceiptParser.parse("Cơm 30.000,00\nGiảm giá 5.000\nTổng tiền 25.000,00");check(c.total()==25000&&c.items().size()==1&&c.items().getFirst().amount()==30000,"decimal formatting and discount");
 if(args.length>0){var d=ReceiptParser.parse(Files.readString(Path.of(args[0])));System.out.println(d);check(d.total()!=null&&d.total()==50000,"real Tesseract output -> parser");}
 }
}
