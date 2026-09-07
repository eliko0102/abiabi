import express from 'express';
import bcryptjs from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';

const router = express.Router();

// Apple Android web flow callback. Apple posts the authorization result here;
// the plugin then receives it through the app's signinwithapple deep link.
router.post('/apple/callback', (req, res) => {
  const params = new URLSearchParams(req.body || {}).toString();
  res.redirect(
    `intent://callback?${params}#Intent;package=com.aiagent.com;scheme=signinwithapple;end`
  );
});

// Signup route
router.post('/signup', async (req, res) => {
  try {
    const { name, email, password, businessType, phone, dateOfBirth } = req.body;

    // Validation
    if (!name || !email || !password || !phone || !dateOfBirth) {
      return res.status(400).json({
        success: false,
        message: 'Ad, e-poçt, şifrə, mobil nömrə və doğum tarixi tələb olunur',
      });
    }

    const parsedDateOfBirth = new Date(dateOfBirth);
    if (Number.isNaN(parsedDateOfBirth.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Doğum tarixi düzgün deyil',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email',
      });
    }

    // Hash password
    const hashedPassword = await bcryptjs.hash(password, 10);

    // Create new user
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      businessType: businessType || '',
      phone,
      dateOfBirth: parsedDateOfBirth,
    });

    // Generate JWT token
    const token = jwt.sign(
      { id: user._id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        businessType: user.businessType,
        phone: user.phone,
        dateOfBirth: user.dateOfBirth,
      },
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({
      success: false,
      message: 'Error registering user',
      error: error.message,
    });
  }
});

// Login route
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    // Find user and include password field
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Compare password
    const isPasswordValid = await bcryptjs.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user._id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        businessType: user.businessType,
        phone: user.phone,
        dateOfBirth: user.dateOfBirth,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error logging in',
      error: error.message,
    });
  }
});

export default router;
