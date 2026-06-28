// Style.jsx
import React from 'react';
import {
  Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Typography
} from '@mui/material';

const orders = [
  { customerId: 1, orderId: 1, vendorId: 1, startDate: '21-5-25', endDate: '21-6-25', orderDate: '1-5-25', price: '200$' },
  { customerId: 1, orderId: 1, vendorId: 1, startDate: '21-5-25', endDate: '21-6-25', orderDate: '1-5-25', price: '200$' },
  { customerId: 1, orderId: 1, vendorId: 1, startDate: '21-5-25', endDate: '21-6-25', orderDate: '1-5-25', price: '200$' },
  { customerId: 1, orderId: 1, vendorId: 1, startDate: '21-5-25', endDate: '21-6-25', orderDate: '1-5-25', price: '200$' },
  { customerId: 1, orderId: 1, vendorId: 1, startDate: '21-5-25', endDate: '21-6-25', orderDate: '1-5-25', price: '200$' },
  { customerId: 1, orderId: 1, vendorId: 1, startDate: '21-5-25', endDate: '21-6-25', orderDate: '1-5-25', price: '200$' },
];

const LastOrdersTable = () => {
  return (
    <Paper
      elevation={3}
      sx={{
        backgroundColor: '#d35400',
        padding: 3,
        borderRadius: 3,
        color: '#fff',
        overflowX: 'auto'
      }}
    >
      <Typography variant="h6" align="center" gutterBottom sx={{ fontWeight: 'bold' }}>
        Last Orders
      </Typography>
      <TableContainer>
        <Table>
          <TableHead>
            <TableRow>
              {['Customer ID', 'Order ID', 'Vendor ID', 'Start Date', 'End Date', 'Order Date', 'Price'].map((header) => (
                <TableCell key={header} sx={{ color: '#fff', fontWeight: 'bold' }}>{header}</TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {orders.map((row, index) => (
              <TableRow key={index}>
                <TableCell sx={{ color: '#fff' }}>{row.customerId}</TableCell>
                <TableCell sx={{ color: '#fff' }}>{row.orderId}</TableCell>
                <TableCell sx={{ color: '#fff' }}>{row.vendorId}</TableCell>
                <TableCell sx={{ color: '#fff' }}>{row.startDate}</TableCell>
                <TableCell sx={{ color: '#fff' }}>{row.endDate}</TableCell>
                <TableCell sx={{ color: '#fff' }}>{row.orderDate}</TableCell>
                <TableCell sx={{ color: '#fff' }}>{row.price}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Paper>
  );
};

export default LastOrdersTable;
