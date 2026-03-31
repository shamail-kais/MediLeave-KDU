package MediLeave.MediLeave.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LeaveDecisionRequest {
    @NotBlank
    private String comment;
}