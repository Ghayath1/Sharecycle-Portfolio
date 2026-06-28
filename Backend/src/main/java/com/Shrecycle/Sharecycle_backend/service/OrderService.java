package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.*;
import com.Shrecycle.Sharecycle_backend.entity.Bicycle;
import com.Shrecycle.Sharecycle_backend.entity.Order;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.enums.OrderStatus;
import com.Shrecycle.Sharecycle_backend.enums.PaymentStatus;
import com.Shrecycle.Sharecycle_backend.repository.BicycleRepository;
import com.Shrecycle.Sharecycle_backend.repository.OrderRepository;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import com.paypal.sdk.exceptions.ApiException;
import com.paypal.sdk.models.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service for order-related operations.
 */
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final BicycleRepository bicycleRepository;
    private final UserRepository userRepository;
    private final PaymentService paymentService;

    public Map<String, ?> getOrderDetails(OrderRequestDTO requestDTO) {
        Bicycle bicycle = bicycleRepository.findById(requestDTO.getBicycleId())
                .orElseThrow(() -> new RuntimeException("Bicycle not found"));

        LocalDate from = LocalDate.parse(requestDTO.getDateFrom());
        LocalDate to = LocalDate.parse(requestDTO.getDateTo());
        long days = ChronoUnit.DAYS.between(from, to) + 1;
        if (days < 1) throw new RuntimeException("Invalid rental period");
        double totalPrice = bicycle.getPrice() * days;

        return Map.of(
                "bicycle", bicycle,
                "from", from,
                "to", to,
                "days", days,
                "totalPrice", totalPrice
        );
    }

    /**
     * Creates a new order.
     *
     * @param requestDTO The DTO containing the new order's details.
     * @param userEmail  The email of the user placing the order.
     * @return The created order's data.
     */
    public Order createOrder(OrderRequestDTO requestDTO, String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        Map<String, ?> orderDetails = getOrderDetails(requestDTO);
        Bicycle bike = (Bicycle) orderDetails.get("bicycle");
        double totalPrice = (double) orderDetails.get("totalPrice");
        LocalDate from = (LocalDate) orderDetails.get("from");
        LocalDate to = (LocalDate) orderDetails.get("to");
        long days = (long) orderDetails.get("days");

        Order order = new Order();
        order.setRenter(user);
        order.setBicycle(bike);
        order.setDateFrom(from);
        order.setDateTo(to);
        order.setRentalDays(days);
        order.setTotalPrice(totalPrice);

        order = orderRepository.save(order);
        return order;
    }

    /**
     * Converts an Order entity to an OrderResponseDTO.
     *
     * @param order The Order entity to convert.
     * @return The converted OrderResponseDTO.
     */
    public OrderResponseDTO toResponseDto(Order order) {
        OrderResponseDTO dto = new OrderResponseDTO();
        dto.setOrderId(order.getId());
        dto.setDateFrom(order.getDateFrom().toString());
        dto.setDateTo(order.getDateTo().toString());
        dto.setRentalDays(order.getRentalDays());
        dto.setTotalPrice(order.getTotalPrice());
        dto.setOrderStatus(order.getStatus());
        if (order.getBicycle() != null) {
            dto.setBikeName(order.getBicycle().getName());
            dto.setBicycleId(order.getBicycle().getId());
            dto.setPricePerDay(order.getBicycle().getPrice());
            if (order.getBicycle().getOwner() != null) {
                dto.setOwner(new UserDTO(order.getBicycle().getOwner()));
            }
        }
        if (order.getRenter() != null) {
            dto.setRenter(new UserDTO(order.getRenter()));
        }
        dto.setOrderDate(LocalDate.from(order.getCreatedAt()));

        return dto;
    }

    /**
     * Converts an Order entity to an OrderResponseForOwnerDTO.
     *
     * @param order The Order entity to convert.
     * @return The converted OrderResponseForOwnerDTO.
     */
    private OrderResponseForOwnerDTO toOwnerDto(Order order) {
        OrderResponseForOwnerDTO dto = new OrderResponseForOwnerDTO();
        dto.setOrderId(order.getId());
        dto.setDateFrom(order.getDateFrom().toString());
        dto.setDateTo(order.getDateTo().toString());
        dto.setRentalDays(order.getRentalDays());
        dto.setTotalPrice(order.getTotalPrice());
        dto.setOrderStatus(order.getStatus());

        if (order.getBicycle() != null) {
            dto.setBikeName(order.getBicycle().getName());
            dto.setBicycleId(order.getBicycle().getId());
            dto.setBikeImageUrl(order.getBicycle().getImageUrl());
            if (order.getBicycle().getOwner() != null) {
                dto.setOwner(new UserDTO(order.getBicycle().getOwner()));
            }
        }
        if (order.getRenter() != null) {
            dto.setRenter(new UserDTO(order.getRenter()));
        }
        return dto;
    }

    /**
     * Retrieves the orders of a specific user.
     *
     * @param userEmail The email of the user.
     * @return A list of the user's orders.
     */
    public List<OrderResponseDTO> getOrdersForUser(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        return orderRepository.findByRenter(user)
                .stream()
                .map(this::toResponseDto)
                .toList();
    }

    public Order getOrderByIdAndEmail(Long id, String userEmail) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (!order.getRenter().getEmail().equals(userEmail)) {
            throw new SecurityException("Not allowed to view this order");
        }

        return order;
    }

    public Order getOrderByPaypalOrderId(String orderId) {
        return orderRepository.findByPayment_PaypalOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
    }

    /**
     * Retrieves an order by its ID.
     *
     * @param id        The ID of the order to retrieve.
     * @param userEmail The email of the user requesting the order.
     * @return The order's data.
     */
    public OrderResponseDTO getOrderResponseDtoByIdAndEmail(Long id, String userEmail) {
        return toResponseDto(this.getOrderByIdAndEmail(id, userEmail));
    }

    private void cancelOrder(Order order) throws ResponseException, IOException, ApiException {
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new ResponseException("Order cannot be cancelled", HttpStatus.CONFLICT.value());
        }

        paymentService.voidAuthorization(order);
        order.setStatus(OrderStatus.CANCELED);
        orderRepository.save(order);
    }

    /**
     * Cancels an order.
     *
     * @param id        The ID of the order to delete.
     * @param userEmail The email of the user requesting the deletion.
     */
    @Transactional
    public void cancelOrder(Long id, String userEmail) throws ResponseException, IOException, ApiException {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (!order.getRenter().getEmail().equals(userEmail)) {
            throw new SecurityException("Not allowed to cancel this order");
        }

        cancelOrder(order);
    }

    /**
     * Retrieves all orders.
     *
     * @return A list of all orders.
     */
    public List<OrderResponseDTO> getAllOrders() {
        return orderRepository.findAll(Sort.by(Sort.Direction.DESC, "id"))
                .stream()
                .map(this::toResponseDto)
                .toList();
    }

    /**
     * Updates an order.
     *
     * @param id        The ID of the order to update.
     * @param dto       The DTO containing the updated order details.
     * @param userEmail The email of the user requesting the update.
     * @return The updated order's data.
     */
    public OrderResponseDTO updateOrder(Long id, OrderRequestDTO dto, String userEmail) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (!order.getRenter().getEmail().equals(userEmail)) {
            throw new SecurityException("Not allowed to update this order");
        }
        return updateCommonFields(order, dto);
    }

    /**
     * Updates an order as an admin.
     *
     * @param id  The ID of the order to update.
     * @param dto The DTO containing the updated order details.
     * @return The updated order's data.
     */
    public OrderResponseDTO updateOrderByAdmin(Long id, OrderRequestDTO dto) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        return updateCommonFields(order, dto);
    }

    /**
     * Updates the common fields of an order.
     *
     * @param order      The order to update.
     * @param requestDTO The DTO containing the new data.
     * @return The updated order's data.
     */
    private OrderResponseDTO updateCommonFields(Order order, OrderRequestDTO requestDTO) {
        Map<String, ?> orderDetails = getOrderDetails(requestDTO);
        Bicycle bike = (Bicycle) orderDetails.get("bicycle");
        double totalPrice = (double) orderDetails.get("totalPrice");
        LocalDate from = (LocalDate) orderDetails.get("from");
        LocalDate to = (LocalDate) orderDetails.get("to");
        long days = (long) orderDetails.get("days");

        order.setBicycle(bike);
        order.setDateFrom(from);
        order.setDateTo(to);
        order.setRentalDays(days);
        order.setTotalPrice(totalPrice);

        return toResponseDto(orderRepository.save(order));
    }

    /**
     * Retrieves the orders for bicycles owned by a specific user.
     *
     * @param ownerEmail The email of the bicycle owner.
     * @return A list of orders for the owner's bicycles.
     */
    public List<OrderResponseForOwnerDTO> getOrdersForOwnedBikes(String ownerEmail) {
        User owner = userRepository.findByEmail(ownerEmail)
                .orElseThrow(() -> new UsernameNotFoundException("Owner not found"));

        return orderRepository.findByBicycleOwner(owner)
                .stream()
                .map(this::toOwnerDto)
                .toList();
    }

    /**
     * Retrieves a compact list of all orders for an admin.
     *
     * @return A list of all orders with a compact view.
     */
    public List<AdminOrderDetailDTO> getAllOrdersForAdmin() {
        return orderRepository.findAllByStatus(OrderStatus.PENDING, Sort.by(Sort.Direction.DESC, "id"))
                .stream()
                .map(order -> AdminOrderDetailDTO.builder()
                        .orderId(order.getId())
                        .customerName(order.getRenter() != null ? order.getRenter().getName() : null)
                        .customerId(order.getRenter().getId())
                        .customerProfileImage(order.getRenter().getImageUrl())
                        .vendorName(order.getBicycle() != null && order.getBicycle().getOwner() != null
                                ? order.getBicycle().getOwner().getName() : null)
                        .vendorId(order.getBicycle() != null && order.getBicycle().getOwner() != null
                                ? order.getBicycle().getOwner().getId() : null)
                        .vendorProfileImage(order.getBicycle() != null && order.getBicycle().getOwner() != null
                                ? order.getBicycle().getOwner().getImageUrl() : null)
                        .bikeName(order.getBicycle() != null ? order.getBicycle().getName() : null)
                        .bikeId(order.getBicycle().getId())
                        .bikeImageUrl(order.getBicycle().getImageUrl())
                        .bikePrice(order.getBicycle().getPrice())
                        .bikeCity(order.getBicycle().getCity())
                        .bikeDate(order.getBicycle().getAvailableFrom().toString())
                        .dateFrom(String.valueOf(order.getDateFrom()))
                        .dateTo(String.valueOf(order.getDateTo()))
                        .orderDate(LocalDate.from(order.getCreatedAt()))
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Retrieves the full details of an order for an admin.
     *
     * @param orderId The ID of the order to retrieve.
     * @return The detailed order information.
     */
    public AdminOrderDetailDTO getOrderDetailsById(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        AdminOrderDetailDTO dto = new AdminOrderDetailDTO();
        Bicycle bike = order.getBicycle();
        User customer = order.getRenter();
        User vendor = bike != null ? bike.getOwner() : null;

        dto.setOrderId(order.getId());
        if (bike != null) {
            dto.setBikeId(bike.getId());
            dto.setBikeName(bike.getName());
            dto.setBikeImageUrl(bike.getImageUrl());
            dto.setBikePrice(bike.getPrice());
            dto.setBikeCity(bike.getCity());
            if (bike.getAvailableFrom() != null) {
                dto.setBikeDate(bike.getAvailableFrom().toString());
            }
        }
        if (customer != null) {
            dto.setCustomerName(customer.getName());
        }
        if (vendor != null) {
            dto.setVendorName(vendor.getName());
        }
        dto.setDateFrom(order.getDateFrom().toString());
        dto.setDateTo(order.getDateTo().toString());

        return dto;
    }

    /**
     * Deletes an order as an admin.
     *
     * @param id The ID of the order to delete.
     */
    @Transactional
    public void cancelOrderByAdmin(Long id) throws ResponseException, IOException, ApiException {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        cancelOrder(order);
    }

    @Transactional
    public String approveOrderByOwner(Long orderId, String ownerEmail) throws ResponseException, IOException, ApiException {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (!order.getBicycle().getOwner().getEmail().equals(ownerEmail)) {
            throw new ResponseException("Not allowed to approve this order", HttpStatus.BAD_REQUEST.value());
        }

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new ResponseException("Not allowed to approve this order", HttpStatus.CONFLICT.value());
        }

        paymentService.CapturePaymentForOrder(order);

        order.setStatus(OrderStatus.APPROVED);
        orderRepository.save(order);

        updateBicycleAvailability(order);
        rejectOverlappingOrders(order);

        return "Order approved successfully";
    }

    private void updateBicycleAvailability(Order order) {
        Bicycle bicycle = order.getBicycle();
        bicycle.setAvailableFrom(order.getDateTo().plusDays(1));
        bicycleRepository.save(bicycle);
    }

    private void rejectOverlappingOrders(Order approvedOrder) throws IOException, ApiException, ResponseException {
        Bicycle bicycle = approvedOrder.getBicycle();
        List<Order> pendingOrders = orderRepository.findByBicycleAndStatusAndPaymentStatus(
                bicycle,
                OrderStatus.PENDING,
                PaymentStatus.AUTHORIZED
        );

        for (Order pendingOrder : pendingOrders) {
            if (pendingOrder.getId().equals(approvedOrder.getId())) {
                continue;
            }

            if (datesOverlap(pendingOrder, approvedOrder)) {
                rejectOrder(pendingOrder);
            }
        }
    }

    private boolean datesOverlap(Order order1, Order order2) {
        return !order1.getDateTo().isBefore(order2.getDateFrom()) && !order1.getDateFrom().isAfter(order2.getDateTo());
    }

    private void rejectOrder(Order order) throws IOException, ApiException, ResponseException {
        paymentService.voidAuthorization(order);
        order.setStatus(OrderStatus.REJECTED);
        orderRepository.save(order);
    }

    @Transactional
    public String rejectOrderByOwner(Long orderId, String ownerEmail) throws ResponseException, IOException, ApiException {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (!order.getBicycle().getOwner().getEmail().equals(ownerEmail)) {
            throw new ResponseException("Not allowed to reject this order", HttpStatus.BAD_REQUEST.value());
        }

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new ResponseException("Order is not in a pending state, cannot reject.", HttpStatus.CONFLICT.value());
        }

        paymentService.voidAuthorization(order);

        order.setStatus(OrderStatus.REJECTED);
        orderRepository.save(order);
        return "Order rejected successfully";
    }

    public PurchaseUnitRequest createPurchaseUnitRequestByOrderRequest(OrderRequestDTO requestDTO) {
        Map<String, ?> orderDetails = getOrderDetails(requestDTO);
        Bicycle bicycle = (Bicycle) orderDetails.get("bicycle");
        double totalPrice = (double) orderDetails.get("totalPrice");

        String currency = "USD";
        String price = Double.toString(totalPrice);
        Item cycleItem = new Item.Builder(
                bicycle.getName(),
                new Money.Builder(currency, price).build(),
                "1"
        ).description(bicycle.getDescription()).sku(bicycle.getId().toString()).category(ItemCategory.PHYSICAL_GOODS).build();

        return new PurchaseUnitRequest.Builder(
                new AmountWithBreakdown.Builder(currency, price)
                        .breakdown(new AmountBreakdown.Builder().itemTotal(new Money(currency, price))
                                .build())
                        .build()
        ).items(Collections.singletonList(cycleItem)).build();
    }

    public void verifyOrder(OrderRequestDTO requestDTO) throws ResponseException {
        Bicycle bicycle = bicycleRepository.findById(requestDTO.getBicycleId())
                .orElseThrow(() -> new RuntimeException("Bicycle not found"));

        LocalDate startDate;
        LocalDate endDate;
        try {
            startDate = LocalDate.parse(requestDTO.getDateFrom());
            endDate = LocalDate.parse(requestDTO.getDateTo());
        } catch (DateTimeParseException e) {
            throw new ResponseException("Bad Date format, use: YYYY-MM-DD", HttpStatus.BAD_REQUEST.value());
        }

        LocalDate availableDate = bicycle.getAvailableFrom();

        if (!startDate.isBefore(endDate) || !startDate.plusDays(1).isAfter(availableDate)) {
            throw new ResponseException("Invalid dates", HttpStatus.CONFLICT.value());
        }
    }
}
