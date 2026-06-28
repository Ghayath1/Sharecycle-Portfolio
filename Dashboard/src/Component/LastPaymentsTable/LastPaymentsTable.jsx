import React from "react";
import {
  Box,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
  TableHead,
  Paper,
  CircularProgress,
  Alert,
} from "@mui/material";
import { useTranslation } from "react-i18next";


const API_BASE = "http://localhost:8080";

const LastPaymentsTable = () => {
  const { t } = useTranslation();

  const [payments, setPayments] = React.useState([]);
  const [loading, setLoading] = React.useState(true);
  const [err, setErr] = React.useState("");

  React.useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      setErr("Not authenticated");
      setLoading(false);
      return;
    }
    (async () => {
      try {
        const res = await fetch(`${API_BASE}/api/payments`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) {
          const text = await res.text().catch(() => "");
          throw new Error(text || `HTTP ${res.status}`);
        }
        const data = await res.json();
        setPayments(Array.isArray(data) ? data : []);
      } catch (e) {
        setErr(e.message || "Failed to load payments");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <Box
      sx={{
        borderRadius: "12px",
        overflow: "hidden",
        border: "2px solid #3498db",
        width: "100%",
        maxWidth: 600,
        margin: "auto",
        mt: 4,
      }}
    >
      <Paper sx={{ backgroundColor: "#d35400", px: 2, py: 3 }}>
        <Typography
          variant="h6"
          align="center"
          fontWeight="bold"
          color="#fff"
          gutterBottom
        >
          {t("Last Payments")}
        </Typography>
        {loading ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
            <CircularProgress color="inherit" />
          </Box>
        ) : err ? (
          <Alert severity="error">{err}</Alert>
        ) : (
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  {[t("ID"), t("Order ID"), t("Status"), t("Paypal Order ID"), t("Authorization ID"), t("Capture ID"), t("Amount")].map((header) => (
                    <TableCell
                      key={header}
                      sx={{ color: "#fff", fontWeight: "bold" }}
                    >
                      {header}
                    </TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {payments.map((row, index) => (
                  <TableRow key={index}>
                    <TableCell sx={{ color: "#fff" }}>{row.id}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.orderId ?? "-"}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.status}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.paypalOrderId}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.authorizationId}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.captureId}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.amount}</TableCell>
                  </TableRow>
                ))}
                {payments.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={7} sx={{ color: "#fff", textAlign: "center" }}>
                      {t("No data")}
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Paper>
    </Box>
  );
};

export default LastPaymentsTable;
