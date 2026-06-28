import React, { useState } from 'react';
import {
  Box,
  Button,
  Container,
  TextField,
  Typography,
  Paper,
  InputAdornment,
  IconButton,
  Alert,
  CircularProgress
} from '@mui/material';
import EmailIcon from '@mui/icons-material/Email';
import LockIcon from '@mui/icons-material/Lock';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8080';

function decodeJwt(jwt) {
  try {
    const [, payload] = jwt.split('.');
    const json = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')));
    return json;
  } catch {
    return null;
  }
}

function extractRoleFromToken(token) {
  const payload = decodeJwt(token);
  if (!payload) return null;

  // أمثلة شائعة حسب الـ backend:
  // 1) claim اسمه role: "ADMIN" | "USER"
  if (payload.role) return payload.role;

  // 2) authorities: ["ROLE_ADMIN", "ROLE_USER"]
  if (Array.isArray(payload.authorities) && payload.authorities.length > 0) {
    const first = String(payload.authorities[0]);
    if (first.startsWith('ROLE_')) return first.replace('ROLE_', '');
  }

  // 3) scope أو scopes
  if (typeof payload.scope === 'string') {
    if (payload.scope.includes('ADMIN')) return 'ADMIN';
    if (payload.scope.includes('USER')) return 'USER';
  }

  return null;
}

const LoginPage = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const [loading, setLoading] = useState(false);
  const [errMsg, setErrMsg] = useState('');

  const togglePasswordVisibility = () => setShowPassword((p) => !p);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrMsg('');
    setLoading(true);

    try {
      const res = await fetch(`${API_BASE}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      // Backend بيرجع 400 مع message: "Invalid email or password"
      if (!res.ok) {
        const text = await res.text().catch(() => '');
        let msg = 'Login failed';
        try {
          const j = JSON.parse(text);
          msg = j.message || msg;
        } catch {
          // ignore
        }
        throw new Error(msg);
      }

      const data = await res.json();

      // أمثلة محتملة للرد بحسب سيرفرك الحالي:
      // { token, role, id, email, username }  <-- إذا عدلت LoginResponse
      // أو { token, status, userDTO }         <-- سيرفرك الحالي للمستخدم
      const token = data.token;
      if (!token) throw new Error('Token missing in response');

      // استخرج الدور من الرد أو من التوكن
      let role =
        data.role ||
        (data.userDTO?.role ? String(data.userDTO.role).toUpperCase() : null) ||
        extractRoleFromToken(token) ||
        'USER';

      // خزّن التوكن + معلومات سريعة
      localStorage.setItem('token', token);
      localStorage.setItem('auth_email', data.email || email);
      localStorage.setItem('auth_role', role);

      // توجيه حسب الدور
      if (role === 'ADMIN') {
        navigate('/summary');
      } else {
        navigate('/');
      }
    } catch (err) {
      setErrMsg(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(to right, #fbeee6, #fff)',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        p: 2,
      }}
    >
      <Paper
        elevation={6}
        sx={{
          p: 4,
          borderRadius: 3,
          width: '100%',
          maxWidth: 420,
          boxShadow: '0px 6px 20px rgba(0,0,0,0.1)',
        }}
      >
        <Typography
          variant="h4"
          align="center"
          gutterBottom
          sx={{ fontWeight: 'bold', color: '#d35400' }}
        >
          {t('Login')}
        </Typography>

        {errMsg && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {errMsg}
          </Alert>
        )}

        <form onSubmit={handleSubmit}>
          <TextField
            fullWidth
            label={t('Email')}
            type="email"
            margin="normal"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <EmailIcon color="action" />
                </InputAdornment>
              ),
            }}
          />

          <TextField
            fullWidth
            label={t('Password')}
            type={showPassword ? 'text' : 'password'}
            margin="normal"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <LockIcon color="action" />
                </InputAdornment>
              ),
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton onClick={togglePasswordVisibility} edge="end">
                    {showPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />

          <Box mt={4}>
            <Button
              type="submit"
              variant="contained"
              fullWidth
              disabled={loading}
              sx={{
                backgroundColor: '#d35400',
                '&:hover': { backgroundColor: '#e36b17' },
                color: 'white',
                textTransform: 'none',
                fontWeight: 'bold',
                py: 1.5,
                fontSize: '16px',
              }}
              startIcon={loading ? <CircularProgress size={20} color="inherit" /> : null}
            >
              {loading ? t('Loading...') : t('Login')}
            </Button>
          </Box>
        </form>
      </Paper>
    </Box>
  );
};

export default LoginPage;
