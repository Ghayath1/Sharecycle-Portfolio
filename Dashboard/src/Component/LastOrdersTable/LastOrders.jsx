import React, { useEffect, useMemo, useState } from "react";
import {
  Box,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Alert,
} from "@mui/material";
import { useTranslation } from "react-i18next";

const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:8080";

function formatDate(iso) {
  if (!iso) return "-";
  try {
    // api يعيد yyyy-MM-dd؛ نعرضها حسب لغة المتصفح
    const d = new Date(iso + "T00:00:00");
    return d.toLocaleDateString();
  } catch {
    return iso;
  }
}

function formatMoney(v, currency = "EUR") {
  if (v == null) return "-";
  try {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency,
      maximumFractionDigits: 2,
    }).format(v);
  } catch {
    return String(v);
  }
}

const LastOrdersTable = () => {
  const { t } = useTranslation();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) {
      setErr("Not authenticated");
      setLoading(false);
      return;
    }
    (async () => {
      try {
        const res = await fetch(`${API_BASE}/api/orders/all`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) {
          const text = await res.text().catch(() => "");
          throw new Error(text || `HTTP ${res.status}`);
        }
        const data = await res.json();

        // ترتيب تنازليًا حسب orderId وخذ آخر 12 (أحدث 12)
        const normalized = Array.isArray(data) ? data : [];
        normalized.sort((a, b) => (b.orderId ?? 0) - (a.orderId ?? 0));
        setRows(normalized.slice(0, 12));
      } catch (e) {
        setErr(e.message || "Failed to load orders");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const headers = useMemo(
    () => [
      t("Customer"),     // userName أو userEmail
      t("OrderID"),
      t("Rental ID"),    // bicycleId
      t("StartDate"),
      t("EndDate"),
      t("OrderDate"),
      t("Price1"),       // total price
    ],
    [t]
  );

  return (
    <Box
      sx={{
        borderRadius: "12px",
        overflow: "hidden",
        border: "2px solid #3498db",
        width: "100%",
        maxWidth: 1000,
        margin: "auto",
        mt: 4,
      }}
    >
      <Paper sx={{ backgroundColor: "#d35400", px: 2, py: 3, minHeight: 120 }}>
        <Typography
          variant="h6"
          align="center"
          fontWeight="bold"
          color="#fff"
          gutterBottom
        >
          {t("LastOrders")}
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
                  {headers.map((header) => (
                    <TableCell key={header} sx={{ color: "#fff", fontWeight: "bold" }}>
                      {header}
                    </TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.orderId}>
                    <TableCell sx={{ color: "#fff" }}>
                       {row.renter?.name || row.renter?.username || row.renter?.email || "-"}
                    </TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.orderId}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{row.bicycleId ?? "-"}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{formatDate(row.dateFrom)}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{formatDate(row.dateTo)}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>{formatDate(row.orderDate)}</TableCell>
                    <TableCell sx={{ color: "#fff" }}>
                      {formatMoney(row.totalPrice, "EUR")}
                    </TableCell>
                  </TableRow>
                ))}
                {rows.length === 0 && (
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

export default LastOrdersTable;
