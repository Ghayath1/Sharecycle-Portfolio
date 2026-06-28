package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.*;
import com.Shrecycle.Sharecycle_backend.service.OrderService;
import com.paypal.sdk.exceptions.ApiException;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;

/**
 * Controller for order-related operations.
 * Provides endpoints for creating, retrieving, updating, and deleting orders.
 */
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    /**
     * Retrieves the orders of the current user.
     *
     * @param userDetails The details of the authenticated user.
     * @return A response entity with a list of the user's orders.
     */
    @GetMapping("/my")
    public ResponseEntity<List<OrderResponseDTO>> getMyOrders(
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        String email = userDetails.getUsername();
        List<OrderResponseDTO> orders = orderService.getOrdersForUser(email);
        return ResponseEntity.ok(orders);
    }

    /**
     * Retrieves an order by its ID.
     * The order must belong to the current user, or the user must be an admin.
     *
     * @param id          The ID of the order to retrieve.
     * @param userDetails The details of the authenticated user.
     * @return A response entity with the order's data.
     */
    @GetMapping("/{id}")
    public ResponseEntity<OrderResponseDTO> getOrderById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        String email = userDetails.getUsername();
        OrderResponseDTO response = orderService.getOrderResponseDtoByIdAndEmail(id, email);
        return ResponseEntity.ok(response);
    }

    /**
     * Deletes an order.
     * The order must be owned by the current user.
     *
     * @param id          The ID of the order to delete.
     * @param userDetails The details of the authenticated user.
     * @return A response entity indicating success.
     */
    @Operation(
            summary = "Cancel a pending order",
            description = """
            Allows a user to cancel their own order if it is still in the 'PENDING' state.

            Upon a successful request, the following changes occur:
            - The **Order Status** is updated from `PENDING` to `CANCELED`.
            - The associated PayPal payment authorization is **voided**, releasing the hold on the user's funds.
            """
    )
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancelOrder(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails
    ) throws ResponseException, IOException, ApiException {
        String email = userDetails.getUsername();
        orderService.cancelOrder(id, email);
        return ResponseEntity.noContent().build();
    }

    /**
     * Updates an order.
     * The order must be owned by the current user.
     *
     * @param id          The ID of the order to update.
     * @param request     The request body with the updated order details.
     * @param userDetails The details of the authenticated user.
     * @return A response entity with the updated order's data.
     */
    @PutMapping("/{id}")
    public ResponseEntity<OrderResponseDTO> updateOrder(
            @PathVariable Long id,
            @RequestBody OrderRequestDTO request,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        String email = userDetails.getUsername();
        OrderResponseDTO updated = orderService.updateOrder(id, request, email);
        return ResponseEntity.ok(updated);
    }

    /**
     * Retrieves orders for bicycles owned by the current user.
     *
     * @param userDetails The details of the authenticated user.
     * @return A response entity with a list of orders for the user's bicycles.
     */
    @PreAuthorize("hasRole('USER')")
    @GetMapping("/for-owner")
    public ResponseEntity<List<OrderResponseForOwnerDTO>> getOrdersForOwner(
            @AuthenticationPrincipal UserDetails userDetails) {
        String email = userDetails.getUsername();
        List<OrderResponseForOwnerDTO> orders = orderService.getOrdersForOwnedBikes(email);
        return ResponseEntity.ok(orders);
    }

    /**
     * Retrieves a compact list of all orders for an admin.
     *
     * @return A list of all orders with a compact view.
     */
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin")
    public List<AdminOrderDetailDTO> getAllOrdersForAdmin() {
        return orderService.getAllOrdersForAdmin();
    }

    /**
     * Retrieves the full details of an order for an admin.
     *
     * @param id The ID of the order to retrieve.
     * @return A response entity with the detailed order information.
     */
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/{id}")
    public ResponseEntity<AdminOrderDetailDTO> getAdminOrderDetails(@PathVariable Long id) {
        AdminOrderDetailDTO dto = orderService.getOrderDetailsById(id);
        return ResponseEntity.ok(dto);
    }

    /**
     * Updates any order as an admin.
     *
     * @param id      The ID of the order to update.
     * @param request The request body with the updated order details.
     * @return A response entity with the updated order's data.
     */
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/admin/{id}")
    public ResponseEntity<OrderResponseDTO> updateOrderByAdmin(
            @PathVariable Long id,
            @RequestBody OrderRequestDTO request
    ) {
        OrderResponseDTO updated = orderService.updateOrderByAdmin(id, request);
        return ResponseEntity.ok(updated);
    }

    /**
     * Deletes any order as an admin.
     *
     * @param id The ID of the order to delete.
     * @return A response entity indicating success.
     */
    @Operation(
            summary = "Cancel a pending order",
            description = """
            Allows an admin to cancel an order if it is still in the 'PENDING' state.

            Upon a successful request, the following changes occur:
            - The **Order Status** is updated from `PENDING` to `CANCELED`.
            - The associated PayPal payment authorization is **voided**, releasing the hold on the user's funds.
            """
    )
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/admin/{id}")
    public ResponseEntity<Void> cancelOrderByAdmin(@PathVariable Long id) throws ResponseException, IOException, ApiException {
        orderService.cancelOrderByAdmin(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Retrieves all orders (admin only).
     *
     * @return A response entity with a list of all orders.
     */
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/all")
    public ResponseEntity<List<OrderResponseDTO>> getAllOrders() {
        return ResponseEntity.ok(orderService.getAllOrders());
    }
    @Operation(
            summary = "Approve a pending order (Bicycle Owner)",
            description = """
            Allows the owner of a bicycle to approve a rental request. This is a critical action that triggers multiple changes in the system.

            Upon a successful request, the following changes occur:
            - The **Order Status** is updated from `PENDING` to `APPROVED`.
            - The previously authorized PayPal payment is **captured**, transferring the funds.
            - The associated **Bicycle's availability date** is updated to the day after this order's end date.
            - Any other `PENDING` orders that overlap with this rental period for the same bicycle will be automatically **rejected**.
            """
    )
    @PostMapping("/{orderId}/approve")
    public ResponseEntity<?> approveOrder(@PathVariable Long orderId, @AuthenticationPrincipal UserDetails userDetails) throws ResponseException, IOException, ApiException {
        String email = userDetails.getUsername();

        return ResponseEntity.ok(orderService.approveOrderByOwner(orderId, email));
    }

    @Operation(
            summary = "Reject a pending order (Bicycle Owner)",
            description = """
            Allows the owner of a bicycle to reject a rental request.

            Upon a successful request, the following changes occur:
            - The **Order Status** is updated from `PENDING` to `REJECTED`.
            - The associated PayPal payment authorization is **voided**, releasing the hold on the renter's funds.
            """
    )
    @PostMapping("/{orderId}/reject")
    public ResponseEntity<?> rejectOrder(@PathVariable Long orderId, @AuthenticationPrincipal UserDetails userDetails) throws ResponseException, IOException, ApiException {
        String email = userDetails.getUsername();
        return ResponseEntity.ok(orderService.rejectOrderByOwner(orderId, email));
    }
}
