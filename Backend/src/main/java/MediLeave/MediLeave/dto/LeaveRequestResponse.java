package MediLeave.MediLeave.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class LeaveRequestResponse {

    private Long id;
    private Long studentId;
    private String studentName;
    private String registrationNo;
    private String departmentName;

    private String leaveType;
    private LocalDate startDate;
    private LocalDate endDate;
    private long totalDays;

    private String reason;
    private String status;

    private String medicalComment;
    private String departmentComment;
    private String finalComment;

    private LocalDateTime submittedAt;
    private LocalDateTime updatedAt;

    private List<String> documents;
}