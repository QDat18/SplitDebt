package com.splitdebt.api.ledger;
import java.util.Map;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.converter.HttpMessageNotReadableException;
@RestControllerAdvice
public class ApiErrors {
 @ExceptionHandler(ResponseStatusException.class) ResponseEntity<?> status(ResponseStatusException e){return ResponseEntity.status(e.getStatusCode()).body(Map.of("message",e.getReason()==null?"Request failed.":e.getReason()));}
 @ExceptionHandler(MethodArgumentNotValidException.class) ResponseEntity<?> invalid(MethodArgumentNotValidException e){return ResponseEntity.badRequest().body(Map.of("message","Check the required fields and amount limits."));}
 @ExceptionHandler(org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class) ResponseEntity<?> parameter(){return ResponseEntity.badRequest().body(Map.of("message","Invalid request parameter."));}
 @ExceptionHandler(IllegalArgumentException.class) ResponseEntity<?> argument(IllegalArgumentException e){return ResponseEntity.badRequest().body(Map.of("message",e.getMessage()));}
 @ExceptionHandler(HttpMessageNotReadableException.class) ResponseEntity<?> malformed(){return ResponseEntity.badRequest().body(Map.of("message","The request contains invalid data."));}
 @ExceptionHandler(DataIntegrityViolationException.class) ResponseEntity<?> conflict(){return ResponseEntity.status(409).body(Map.of("message","The record already exists or changed. Refresh and try again."));}
 @ExceptionHandler(Exception.class) ResponseEntity<?> unavailable(Exception e){org.slf4j.LoggerFactory.getLogger(ApiErrors.class).error("API request failed",e);return ResponseEntity.internalServerError().body(Map.of("message","Something went wrong. Please try again."));}
}
