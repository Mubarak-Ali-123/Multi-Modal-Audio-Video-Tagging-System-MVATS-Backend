import mongoose from 'mongoose';

/**
 * Connect to MongoDB database
 * Handles both local MongoDB and MongoDB Atlas connections
 */
const connectDB = async () => {
  try {
    // Check if MONGODB_URI is set
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI is not defined in .env file');
    }

    // Connection options - removed deprecated options
    const options = {};

    // For MongoDB Atlas (cloud), ensure SSL is handled properly
    // For local MongoDB, no special SSL config needed
    if (process.env.MONGODB_URI.includes('mongodb+srv://')) {
      // MongoDB Atlas connection
      options.serverSelectionTimeoutMS = 5000;
    }

    const conn = await mongoose.connect(process.env.MONGODB_URI, options);

    console.log(`MongoDB Connected: ${conn.connection.host}`);
    console.log(`Database: ${conn.connection.name}`);
  } catch (error) {
    console.error(`Error connecting to MongoDB: ${error.message}`);
    console.error('\nTroubleshooting tips:');
    console.error('1. Check if MongoDB is running (for local)');
    console.error('2. Verify MONGODB_URI in .env file');
    console.error('3. For MongoDB Atlas, check network access and credentials');
    console.error('4. For local MongoDB, use: mongodb://localhost:27017/mvats');
    console.warn('\n⚠️  Server will continue running without database connection');
    console.warn('Database operations will fail until MongoDB is available.\n');
  }
};

export default connectDB;
