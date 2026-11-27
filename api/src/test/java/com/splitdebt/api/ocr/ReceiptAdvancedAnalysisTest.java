package com.splitdebt.api.ocr;

import java.util.List;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ReceiptAdvancedAnalysisTest {
    @Test void simpleTwoColumnReceiptKeepsUnknownQuantity() {
        var table=List.of(List.of("Tên hàng","Thành tiền"),List.of("Cơm gà","50.000"));
        var candidates=ReceiptAdvancedAnalysis.analyze(new ReceiptAdvancedAnalysis.Payload(
                "Cơm gà 50.000\nTổng 50.000\nNgày 27/11/2026",List.of(),List.of(table),"structure"));
        assertEquals(2,candidates.size());var result=candidates.getLast().result();
        assertEquals(1,result.items().size());assertNull(result.items().getFirst().quantity());
        assertTrue(result.warnings().stream().anyMatch(w->w.contains("thiếu cột")));
        assertTrue(ReceiptAdvancedAnalysis.needsReview(result));
    }
    @Test void inconsistentStructuredAmountsAreNotAccepted() {
        var table=List.of(List.of("Tên hàng","SL","Đơn giá","Thành tiền"),List.of("Cơm gà","2","50.000","80.000"));
        var candidates=ReceiptAdvancedAnalysis.analyze(new ReceiptAdvancedAnalysis.Payload("Tổng 80.000",List.of(),List.of(table),"structure"));
        assertEquals(1,candidates.size());
    }
    @Test void confidenceMustBeFiniteAndWithinPercentageRange() {
        assertFalse(new ReceiptLayoutAnalyzer.Word("Cơm",0,0,50,20,Double.NaN).valid());
        assertFalse(new ReceiptLayoutAnalyzer.Word("Cơm",0,0,50,20,101.0).valid());
        assertTrue(new ReceiptLayoutAnalyzer.Word("Cơm",0,0,50,20,98.0).valid());
    }
}
