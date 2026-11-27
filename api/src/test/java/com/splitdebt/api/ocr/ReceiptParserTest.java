package com.splitdebt.api.ocr;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ReceiptParserTest {
    @Test void standardReceipt() {
        var result=ReceiptParser.parse("Cơm gà 45.000\nTrà đá 5.000\nTổng cộng 50.000 đ");
        assertEquals(50000L,result.total());
        assertEquals(2,result.items().size());
        assertNull(result.items().getFirst().quantity());
        assertFalse(result.warnings().isEmpty());
    }
    @Test void noTotalDoesNotGuess() {
        assertNull(ReceiptParser.parse("Cơm 40.000\nNước 10.000").total());
    }
    @Test void separateTotalAndIgnoreTax() {
        var result=ReceiptParser.parse("Phở 50,000\nVAT 5,000\nTổng thanh toán:\n55,000 VND");
        assertEquals(55000L,result.total()); assertEquals(1,result.items().size()); assertFalse(result.warnings().isEmpty());
    }
    @Test void ambiguousTotalRequiresReview() {
        assertNull(ReceiptParser.parse("Tổng cộng 40.000\nTổng tiền 50.000").total());
    }
    @Test void decimalsAndDiscount() {
        var result=ReceiptParser.parse("Cơm 30.000,00\nGiảm giá 5.000\nTổng tiền 25.000,00");
        assertEquals(25000L,result.total()); assertEquals(1,result.items().size()); assertEquals(30000L,result.items().getFirst().amount());
    }
    @Test void structuredItemsAndDate() {
        var r=ReceiptParser.parse("Nhà hàng ABC\nNgày 26/11/2026\nCơm gà 2 45.000 90.000\nTrà đá 3 x 5k = 15k\nTổng thanh toán 105.000");
        assertEquals(105000L,r.total()); assertEquals("2026-11-26",r.date());
        assertEquals(2,r.items().getFirst().quantity()); assertEquals(45000L,r.items().getFirst().unitPrice());
        assertEquals(15000L,r.items().getLast().amount()); assertTrue(r.warnings().isEmpty());
    }
    @Test void inconsistentRowDoesNotGuess() {
        var r=ReceiptParser.parse("Cơm 2 45.000 80.000\nTổng 80.000");
        assertNull(r.items().getFirst().quantity()); assertEquals(80000L,r.items().getFirst().amount());
    }
    @Test void invalidDate() { assertNull(ReceiptParser.parse("Ngày 31/02/2026\nTổng 50.000").date()); }
    @Test void multiplier() { assertEquals(90000L,ReceiptParser.parse("Cơm 2 x 45k\nTổng 90k").items().getFirst().amount()); }
    @Test void payableTotalWinsOverPreTaxTotal() {
        var r=ReceiptParser.parse("Phở 50.000\nTổng tiền 50.000\nVAT 5.000\nSố tiền phải trả (VNĐ): 55.000\nKhách đưa 100.000\nTiền trả lại 45.000");
        assertEquals(55000L,r.total());assertEquals(1,r.items().size());
    }
    @Test void commonPosTotalLabelsAndSpacing() {
        assertEquals(125000L,ReceiptParser.parse("THANH TOÁN (VND):\n125\u00a0000").total());
        assertEquals(125000L,ReceiptParser.parse("Thành tiền 125.000,-").total());
        assertEquals(125000L,ReceiptParser.parse("TOTAL (VND) 125,000.00").total());
    }
    @Test void shortAndIsoSlashDates() {
        assertEquals("2026-11-27",ReceiptParser.parse("Ngày 27/11/26\nTổng 50.000").date());
        assertEquals("2026-11-27",ReceiptParser.parse("Date 2026/11/27\nTổng 50.000").date());
    }
    @Test void monetarySeparatorsAreNeverGuessed() {
        assertEquals(1250000L,ReceiptParser.money("1.250.000,00 ₫"));
        assertEquals(1500L,ReceiptParser.money("1,5k"));
        assertEquals(45000L,ReceiptParser.money("45k"));
        assertNull(ReceiptParser.money("45.12"));assertNull(ReceiptParser.money("1,234.567"));
        assertNull(ReceiptParser.money("-50.000"));assertNull(ReceiptParser.money("O0.000"));
    }
    @Test void wrappedNameAndPrintedRowNumber() {
        var r=ReceiptParser.parse("ABC MART\nNgày 27/11/2026\n1. Cà phê sữa\n2 30.000 60.000\nTổng 60.000");
        assertEquals(1,r.items().size());assertEquals("Cà phê sữa",r.items().getFirst().name());
        assertEquals(2,r.items().getFirst().quantity());assertEquals("ABC MART",r.merchant());
    }
    @Test void serviceAndTenderRowsAreNotMerchandise() {
        var r=ReceiptParser.parse("Phở 50.000\nPhí phục vụ 5.000\nChiết khấu 2.000\nTiền khách đưa 100.000\nTổng thanh toán 53.000");
        assertEquals(1,r.items().size());assertEquals(53000L,r.total());assertFalse(r.warnings().isEmpty());
    }
    @Test void totalDiscountIsNotTheFinalAmount() {
        var r=ReceiptParser.parse("Cơm 50.000\nTổng giảm giá 5.000\nTotal discount 5.000\nTổng cộng 45.000");
        assertEquals(45000L,r.total());assertEquals(1,r.items().size());
    }
    @Test void foreignCurrencyRequiresReview() {
        assertTrue(ReceiptParser.parse("Coffee 5 USD\nTOTAL 5 USD").warnings().stream().anyMatch(w->w.contains("ngoại tệ")));
    }
    @Test void absentTextIsHandled() {assertNull(ReceiptParser.parse(null).total());}
    @Test void negativeRefundAndReceiptMetadataAreNotPositiveProducts() {
        var r=ReceiptParser.parse("Số hóa đơn 12345\nGiờ 20:45\nTrả hàng -50.000\nCơm 45.000\nTổng 45.000");
        assertEquals(1,r.items().size());assertEquals("Cơm",r.items().getFirst().name());
    }
    @Test void numericBrandNamesArePreserved() {
        var r=ReceiptParser.parse("7 Up 15.000\n3 Miền\n1 5.000 5.000\nTổng 20.000");
        assertEquals(2,r.items().size());assertEquals("7 Up",r.items().getFirst().name());
        assertEquals("3 Miền",r.items().getLast().name());
    }
    @Test void actualCachedPaddleSmokeHandlesDroppedVietnameseGlyphs() {
        var r=ReceiptParser.parse("HÓA ĐON\nCom gà 45.000\nTrà đá 5.000\nTng cng 50.000 VND");
        assertEquals(50000L,r.total());assertEquals(2,r.items().size());
        assertEquals(45000L,r.items().getFirst().amount());assertEquals(5000L,r.items().getLast().amount());
    }
}
