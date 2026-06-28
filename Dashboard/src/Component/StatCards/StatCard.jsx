import React, { useEffect, useState } from "react";
import { Grid, Paper, Typography, CircularProgress, Alert } from "@mui/material";
import { useTranslation } from "react-i18next";

const API_BASE = "http://localhost:8080";

const StatCards = () => {
  const { t } = useTranslation();

  const [stats, setStats] = useState({
    userCount: 0,
    orderCount: 0,
    bicycleCount: 0,
    totalIncome: 0,
  });
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
        // Get dashboard stats
        const statsRes = await fetch(`${API_BASE}/api/admins/dashboard`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!statsRes.ok) {
          const text = await statsRes.text().catch(() => "");
          throw new Error(text || `HTTP ${statsRes.status}`);
        }
        const statsData = await statsRes.json();

        // Get payment summary
        const payRes = await fetch(`${API_BASE}/api/payments/summary`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        let totalIncome = 0;
        if (payRes.ok) {
          const payData = await payRes.json();
          totalIncome = payData.totalIncome ?? 0;
        }

        setStats({
          userCount: statsData.userCount ?? 0,
          orderCount: statsData.orderCount ?? 0,
          bicycleCount: statsData.bicycleCount ?? 0,
          totalIncome,
        });
      } catch (e) {
        setErr(e.message || "Failed to load dashboard stats");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) {
    return (
      <Grid container justifyContent="center" sx={{ mt: 4 }}>
        <CircularProgress />
      </Grid>
    );
  }

  if (err) {
    return (
      <Grid container justifyContent="center" sx={{ mt: 4 }}>
        <Alert severity="error">{err}</Alert>
      </Grid>
    );
  }

  const cards = [
    { title: t("User"), value: stats.userCount },
    { title: t("Order"), value: stats.orderCount },
    { title: t("Bicycles"), value: stats.bicycleCount },
    {
      title: t("Income"),
      value: new Intl.NumberFormat(undefined, {
        style: "currency",
        currency: "EUR", // بدك USD؟ غيّرها
        maximumFractionDigits: 2,
      }).format(stats.totalIncome || 0),
      bold: true,
    },
  ];

  return (
    <Grid container spacing={2} justifyContent="center" sx={{ mt: 4 }}>
      {cards.map((c, i) => (
        <Grid item xs={6} sm={3} key={i}>
          <Paper
            elevation={3}
            sx={{
              backgroundColor: "#d35400",
              padding: 2,
              borderRadius: 2,
              textAlign: "center",
              color: "#fff",
            }}
          >
            <Typography variant="subtitle1" gutterBottom>
              {c.title}
            </Typography>
            <Typography variant="h5" fontWeight={c.bold ? "bold" : "normal"}>
              {c.value}
            </Typography>
          </Paper>
        </Grid>
      ))}
    </Grid>
  );
};

export default StatCards;
