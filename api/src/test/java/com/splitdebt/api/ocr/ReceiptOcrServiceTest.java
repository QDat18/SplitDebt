package com.splitdebt.api.ocr;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ReceiptOcrServiceTest {
    @Test void tsvUsesRealWordsAndIgnoresStructuralRows() {
        String tsv="level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n"
                +"4\t1\t1\t1\t1\t0\t10\t10\t200\t20\t-1\t\n"
                +"5\t1\t1\t1\t1\t1\t10\t10\t50\t20\t98\tCơm\n"
                +"5\t1\t1\t1\t1\t2\t150\t10\t60\t20\t97\t50.000\n"
                +"5\t1\t1\t1\t2\t1\t10\t50\t50\t20\t99\tTổng\n"
                +"5\t1\t1\t1\t2\t2\t150\t50\t60\t20\t99\t50.000\n";
        var result=ReceiptOcrService.parseTsv(tsv);
        assertEquals(50000L,result.total());assertEquals(1,result.items().size());
        assertEquals("Cơm",result.items().getFirst().name());
    }
    @Test void corruptTsvDoesNotBecomeReceiptData() {
        var result=ReceiptOcrService.parseTsv("5\t1\t1\t1\t1\t1\tNaN\t0\t50\t20\t99\t50.000\n");
        assertTrue(result.items().isEmpty());assertNull(result.total());
    }
}
