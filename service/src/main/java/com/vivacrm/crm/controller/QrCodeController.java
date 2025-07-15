package com.vivacrm.crm.controller;

import com.google.zxing.WriterException;
import com.vivacrm.crm.security.QrCodeUtil;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;

@RestController
@RequestMapping("/auth")
public class QrCodeController {

    @GetMapping("/totp-qr")
    public ResponseEntity<byte[]> getTotpQr(
            @RequestParam String username,
            @RequestParam String secret,
            @RequestParam(defaultValue = "Vivacrm") String issuer) throws IOException, WriterException {

        String uri = String.format(
                "otpauth://totp/%s:%s?secret=%s&issuer=%s&digits=6&period=30",
                issuer, username, secret, issuer);

        byte[] qrImage = QrCodeUtil.generateQRCodeImage(uri, 240, 240);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.IMAGE_PNG);
        return ResponseEntity.ok().headers(headers).body(qrImage);
    }
}
