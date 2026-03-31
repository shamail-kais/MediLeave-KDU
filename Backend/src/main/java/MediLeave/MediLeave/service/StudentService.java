package MediLeave.MediLeave.service;

import MediLeave.MediLeave.dto.LeaveRequestCreateRequest;
import MediLeave.MediLeave.dto.LeaveRequestResponse;
import MediLeave.MediLeave.dto.UserResponse;
import MediLeave.MediLeave.entity.LeaveDocument;
import MediLeave.MediLeave.entity.LeaveRequest;
import MediLeave.MediLeave.entity.LeaveStatus;
import MediLeave.MediLeave.entity.User;
import MediLeave.MediLeave.exception.ApiException;
import MediLeave.MediLeave.repository.LeaveDocumentRepository;
import MediLeave.MediLeave.repository.LeaveRequestRepository;
import MediLeave.MediLeave.repository.UserRepository;
import MediLeave.MediLeave.security.AuthUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final UserRepository userRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final LeaveDocumentRepository leaveDocumentRepository;
    private final FileStorageService fileStorageService;

    public UserResponse getProfile(AuthUser authUser) {
        User user = getCurrentUser(authUser);
        return mapUser(user);
    }

    public LeaveRequestResponse createLeaveRequest(AuthUser authUser,
                                                   LeaveRequestCreateRequest request,
                                                   List<MultipartFile> files) {
        User student = getCurrentUser(authUser);

        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new ApiException("End date cannot be before start date");
        }

        LeaveRequest leaveRequest = LeaveRequest.builder()
                .student(student)
                .leaveType(request.getLeaveType())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .reason(request.getReason())
                .status(LeaveStatus.SUBMITTED)
                .build();

        leaveRequestRepository.save(leaveRequest);

        if (files != null) {
            for (MultipartFile file : files) {
                String stored = fileStorageService.saveFile(file);

                LeaveDocument doc = LeaveDocument.builder()
                        .fileName(file.getOriginalFilename())
                        .storedFileName(stored)
                        .filePath(stored)
                        .contentType(file.getContentType())
                        .fileSize(file.getSize())
                        .leaveRequest(leaveRequest)
                        .build();

                leaveDocumentRepository.save(doc);
            }
        }

        return mapLeave(leaveRequest);
    }

    public List<LeaveRequestResponse> getMyRequests(AuthUser authUser) {
        User student = getCurrentUser(authUser);
        return leaveRequestRepository.findByStudentOrderBySubmittedAtDesc(student)
                .stream()
                .map(this::mapLeave)
                .toList();
    }

    public LeaveRequestResponse getMyRequest(AuthUser authUser, Long requestId) {
        User student = getCurrentUser(authUser);

        LeaveRequest leaveRequest = leaveRequestRepository.findById(requestId)
                .orElseThrow(() -> new ApiException("Leave request not found"));

        if (!leaveRequest.getStudent().getId().equals(student.getId())) {
            throw new ApiException("You cannot access this request");
        }

        return mapLeave(leaveRequest);
    }

    private User getCurrentUser(AuthUser authUser) {
        return userRepository.findById(authUser.getUserId())
                .orElseThrow(() -> new ApiException("User not found"));
    }

    private UserResponse mapUser(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .registrationNo(user.getRegistrationNo())
                .role(user.getRole().name())
                .departmentName(user.getDepartment() != null ? user.getDepartment().getName() : null)
                .faculty(user.getDepartment() != null ? user.getDepartment().getFaculty() : null)
                .build();
    }

    private LeaveRequestResponse mapLeave(LeaveRequest request) {
        long totalDays = ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate()) + 1;

        List<String> docs = leaveDocumentRepository.findByLeaveRequest(request)
                .stream()
                .map(LeaveDocument::getFileName)
                .toList();

        return LeaveRequestResponse.builder()
                .id(request.getId())
                .studentId(request.getStudent().getId())
                .studentName(request.getStudent().getFullName())
                .registrationNo(request.getStudent().getRegistrationNo())
                .departmentName(request.getStudent().getDepartment() != null
                        ? request.getStudent().getDepartment().getName() : null)
                .leaveType(request.getLeaveType().name())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .totalDays(totalDays)
                .reason(request.getReason())
                .status(request.getStatus().name())
                .medicalComment(request.getMedicalComment())
                .departmentComment(request.getDepartmentComment())
                .finalComment(request.getFinalComment())
                .submittedAt(request.getSubmittedAt())
                .updatedAt(request.getUpdatedAt())
                .documents(docs)
                .build();
    }
}