import React from 'react';
import {
  Box,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper
} from '@mui/material';
import { useTranslation } from 'react-i18next';

const API_BASE = "http://localhost:8080";

const UserTable = () => {
  const { t } = useTranslation();
  const [users, setUsers] = React.useState([]);
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
        const res = await fetch(`${API_BASE}/api/user/all`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) {
          const text = await res.text().catch(() => "");
          throw new Error(text || `HTTP ${res.status}`);
        }
        const data = await res.json();
        setUsers(Array.isArray(data) ? data : []);
      } catch (e) {
        setErr(e.message || "Failed to load users");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <Box sx={{ mt: 6, px: 3, textAlign: 'center' }}>
      {/* Title */}
      <Box
        sx={{
          display: 'inline-block',
          backgroundColor: '#d35400',
          color: 'white',
          fontWeight: 'bold',
          px: 4,
          py: 1,
          borderRadius: '8px',
          mb: 4,
        }}
      >
        <Typography variant="h5">{t('Users')}</Typography>
      </Box>

      <TableContainer
        component={Paper}
        sx={{
          border: '1px solid #d35400',
          borderRadius: 2,
          overflow: 'hidden',
          overflowX: 'auto',
        }}
      >
        {/* Only one child allowed, so use fragment for conditional rendering */}
        <>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <Typography>{t('Loading...')}</Typography>
            </Box>
          ) : err ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <Typography color="error">{err}</Typography>
            </Box>
          ) : (
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 'bold' }}>{t('Image')}</TableCell>
                  <TableCell sx={{ fontWeight: 'bold' }}>{t('User ID')}</TableCell>
                  <TableCell sx={{ fontWeight: 'bold' }}>{t('Name')}</TableCell>
                  <TableCell sx={{ fontWeight: 'bold' }}>{t('Phone')}</TableCell>
                  <TableCell sx={{ fontWeight: 'bold' }}>{t('E-Mail')}</TableCell>
                  <TableCell sx={{ fontWeight: 'bold' }}>{t('City')}</TableCell>
                  <TableCell sx={{ fontWeight: 'bold' }}>{t('Age')}</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.map((row, index) => (
                  <TableRow
                    key={row.id || index}
                    sx={{ backgroundColor: index % 2 === 0 ? '#efb197' : 'inherit' }}
                  >
                    <TableCell>
                      {row.imageUrl ? (
                        <img src={API_BASE + row.imageUrl} alt={row.name} style={{ width: 40, height: 40, borderRadius: '50%' }} />
                      ) : (
                        <Box sx={{ width: 40, height: 40, borderRadius: '50%', bgcolor: '#ccc', display: 'inline-block' }} />
                      )}
                    </TableCell>
                    <TableCell>{row.id}</TableCell>
                    <TableCell>{row.name}</TableCell>
                    <TableCell>{row.iphoneNumber ?? '-'}</TableCell>
                    <TableCell>{row.email}</TableCell>
                    <TableCell>{row.city ?? '-'}</TableCell>
                    <TableCell>{row.age ?? '-'}</TableCell>
                  </TableRow>
                ))}
                {users.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={7} sx={{ textAlign: 'center' }}>{t('No data')}</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </>
      </TableContainer>
    </Box>
  );
};

export default UserTable;
