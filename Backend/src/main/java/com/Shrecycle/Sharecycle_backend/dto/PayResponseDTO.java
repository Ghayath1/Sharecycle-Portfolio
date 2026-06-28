package com.Shrecycle.Sharecycle_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PayResponseDTO {
    public String approvalUrl;
    public String paypalOrderId;
}
