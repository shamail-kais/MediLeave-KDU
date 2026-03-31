package MediLeave.MediLeave.service;

import MediLeave.MediLeave.exception.ApiException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.util.UUID;

@Service
public class FileStorageService {

    @Value("${app.upload.dir}")
    private String uploadDir;

    public String saveFile(MultipartFile file) {
        try {
            Files.createDirectories(Paths.get(uploadDir));

            String original = StringUtils.cleanPath(file.getOriginalFilename());
            String stored = UUID.randomUUID() + "_" + original;

            Path path = Paths.get(uploadDir, stored);
            Files.copy(file.getInputStream(), path, StandardCopyOption.REPLACE_EXISTING);

            return stored;
        } catch (IOException e) {
            throw new ApiException("Failed to store file");
        }
    }
}