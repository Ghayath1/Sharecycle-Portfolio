import React, { useState, useEffect } from 'react';
import {
  Avatar,
  Box,
  Grid,
  Typography,
  Paper,
  Stack,
  Button,
  CircularProgress,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';

const BACKEND_URL = 'http://localhost:8080';

const getRandomColor = () => {
  const colors = [
    '#e74c3c', '#2ecc71', '#3498db', '#f1c40f', 
    '#9b59b6', '#1abc9c', '#d35400', '#2980b9'
  ];
  return colors[Math.floor(Math.random() * colors.length)];
};

const ChatMessage = ({ sender, messageText, messageTime, messageDate, reverse }) => (
  <Box
    sx={{
      display: 'flex',
      flexDirection: reverse ? 'row-reverse' : 'row',
      alignItems: 'center',
      justifyContent: 'flex-start',
      mb: 2,
      gap: 2,
      width: "100%",
      maxWidth: "800px"
    }}
  >
    <Avatar
      src={sender}
      sx={{ width: 40, height: 40 }}
    />
    <Paper
      elevation={1}
      sx={{
        p: 2,
        backgroundColor: reverse ? '#f5f6fa' : '#d35400',
        color: reverse ? '#2f3640' : 'white',
        borderRadius: 2,
        maxWidth: '60%'
      }}
    >
      <Typography variant="body1">
        {messageText}
      </Typography>
    </Paper>
    <Box>
      <Typography
        variant="caption"
        sx={{ display: 'block', color: '#7f8c8d' }}
      >
        {messageTime}
      </Typography>
      <Typography
        variant="caption"
        sx={{ display: 'block', color: '#7f8c8d', mt: 0.5 }}
      >
        {messageDate}
      </Typography>
    </Box>
  </Box>
);

const ChatLayout = () => {
  const [chatRooms, setChatRooms] = useState([]);
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [colors] = useState(() => 
    Array.from({ length: 20 }, () => getRandomColor())
  );

  useEffect(() => {
    fetchChatRooms();
  }, []);

  useEffect(() => {
    if (selectedRoom) {
      fetchMessages(selectedRoom.senderId, selectedRoom.receiverId);
    }
  }, [selectedRoom]);

  const fetchChatRooms = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await fetch(`${BACKEND_URL}/chat-rooms`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error(`Failed to fetch chat rooms: ${response.status}`);
      }
      
      const data = await response.json();
      setChatRooms(data);
    } catch (error) {
      console.error('Error fetching chat rooms:', error);
      setError(error.message);
      setChatRooms([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchMessages = async (senderId, receiverId) => {
    try {
      setLoading(true);
      const response = await fetch(`${BACKEND_URL}/messages/${senderId}/${receiverId}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      if (!response.ok) throw new Error('Failed to fetch messages');
      const data = await response.json();
      setMessages(data);
    } catch (error) {
      console.error('Error fetching messages:', error);
      setError(error.message);
      setMessages([]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Grid container sx={{ height: '100vh' }}>
      {/* Sidebar with Chat Rooms */}
      <Grid item xs={2} sx={{ backgroundColor: '#f5f6fa', p: 2, borderRight: '1px solid #dcdde1' }}>
        <Typography variant="h6" sx={{ mb: 3, color: '#2f3640' }}>
          Chat Rooms
        </Typography>
        {loading && !selectedRoom ? (
          <Box display="flex" justifyContent="center" alignItems="center" height="100px">
            <CircularProgress size={24} />
          </Box>
        ) : error && !selectedRoom ? (
          <Box p={2}>
            <Typography color="error" variant="body2">
              {error}
            </Typography>
          </Box>
        ) : chatRooms.length === 0 ? (
          <Box p={2}>
            <Typography color="textSecondary" variant="body2">
              No chat rooms available
            </Typography>
          </Box>
        ) : (
          <Stack spacing={2}>
            {chatRooms.map((room, index) => (
              <Paper
                key={room.chatRoomId}
                elevation={selectedRoom?.chatRoomId === room.chatRoomId ? 3 : 1}
                sx={{
                  p: 2,
                  cursor: 'pointer',
                  backgroundColor: colors[index % colors.length],
                  color: 'white',
                  transition: 'all 0.2s',
                  '&:hover': {
                    transform: 'translateY(-2px)',
                    boxShadow: 3,
                  },
                }}
                onClick={() => setSelectedRoom(room)}
              >
                <Typography variant="subtitle2">
                  Room #{room.chatRoomId}
                </Typography>
              </Paper>
            ))}
          </Stack>
        )}
      </Grid>

      {/* Main Chat Area */}
      <Grid item xs={10} sx={{ p: 4, overflowY: 'auto' }}>
        {selectedRoom ? (
          <>
            <Typography variant="h6" sx={{ mb: 4, color: '#2f3640' }}>
              Chat Room #{selectedRoom.chatRoomId}
            </Typography>
            {loading ? (
              <Box display="flex" justifyContent="center" alignItems="center" height="50vh">
                <CircularProgress />
              </Box>
            ) : messages.length === 0 ? (
              <Box display="flex" justifyContent="center" alignItems="center" height="50vh">
                <Typography color="textSecondary">
                  No messages in this chat room
                </Typography>
              </Box>
            ) : (
              messages.map((message, index) => (
                console.log(message),
                <ChatMessage
                  key={index}
                  sender={BACKEND_URL+message.senderUser.imageUrl}
                  messageText={message.content}
                  messageTime={new Date(message.createdAt).toLocaleTimeString()}
                  messageDate={new Date(message.createdAt).toLocaleDateString()}
                  reverse={message.senderId !== selectedRoom.senderId}
                />
              ))
            )}
          </>
        ) : (
          <Box display="flex" justifyContent="center" alignItems="center" height="100%">
            <Typography variant="h6" color="textSecondary">
              Select a chat room to view messages
            </Typography>
          </Box>
        )}
      </Grid>
    </Grid>
  );
};

export default ChatLayout;
