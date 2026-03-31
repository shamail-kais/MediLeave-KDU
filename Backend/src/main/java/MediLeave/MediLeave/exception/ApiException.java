package MediLeave.MediLeave.exception;


public class ApiException extends RuntimeException {
    public ApiException(String message) {
        super(message);
    }
}