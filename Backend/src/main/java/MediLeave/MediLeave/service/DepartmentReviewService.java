package MediLeave.MediLeave.service;

import MediLeave.MediLeave.dto.LeaveDecisionRequest;
import MediLeave.MediLeave.dto.LeaveRequestResponse;
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

import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DepartmentReviewService {

    private final LeaveRequestRepository leaveRequestRepository;
    private final LeaveDocumentRepository leaveDocumentRepository;
    private final UserRepository userRepository;

    public List<LeaveRequestResponse> getVerifiedRequests() {
        return leaveRequestRepository.findByStatusOrderBySubmittedAtDesc(LeaveStatus.MEDICALLY_VERIFIED)
                .stream()
                .map(this::mapLeave)
                .toList();
    }

    public LeaveRequestResponse approve(AuthUser authUser, Long id, LeaveDecisionRequest request) {
        User reviewer = getCurrentUser(authUser);

        LeaveRequest leaveRequest = leaveRequestRepository.findById(id)
                .orElseThrow(() -> new ApiException("Leave request not found"));

        if (leaveRequest.getStatus() != LeaveStatus.MEDICALLY_VERIFIED) {
            throw new ApiException("Only medically verified requests can be approved");
        }

        leaveRequest.setStatus(LeaveStatus.APPROVED);
        leaveRequest.setDepartmentComment(request.getComment());
        leaveRequest.setDepartmentReviewer(reviewer);

        leaveRequestRepository.save(leaveRequest);
        return mapLeave(leaveRequest);
    }

    public LeaveRequestResponse reject(AuthUser authUser, Long id, LeaveDecisionRequest request) {
        User reviewer = getCurrentUser(authUser);

        LeaveRequest leaveRequest = leaveRequestRepository.findById(id)
                .orElseThrow(() -> new ApiException("Leave request not found"));

        if (leaveRequest.getStatus() != LeaveStatus.MEDICALLY_VERIFIED) {
            throw new ApiException("Only medically verified requests can be rejected");
        }

        leaveRequest.setStatus(LeaveStatus.REJECTED);
        leaveRequest.setDepartmentComment(request.getComment());
        leaveRequest.setDepartmentReviewer(reviewer);

        leaveRequestRepository.save(leaveRequest);
        return mapLeave(leaveRequest);
    }

    private User getCurrentUser(AuthUser authUser) {
        return userRepository.findById(authUser.getUserId())
                .orElseThrow(() -> new ApiException("User not found"));
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

    public List<LeaveRequestResponse> getProcessedRequests() {
        List<LeaveRequest> approved = leaveRequestRepository
                .findByStatusOrderBySubmittedAtDesc(LeaveStatus.APPROVED);
        List<LeaveRequest> rejected = leaveRequestRepository
                .findByStatusOrderBySubmittedAtDesc(LeaveStatus.REJECTED);
        List<LeaveRequest> combined = new ArrayList<>();
        combined.addAll(approved);
        combined.addAll(rejected);
        combined.sort((a, b) -> b.getUpdatedAt().compareTo(a.getUpdatedAt()));
        return combined.stream().map(this::mapLeave).toList();
    }
}