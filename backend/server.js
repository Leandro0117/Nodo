import { createServer } from "http";
import express from "express";
import cors from "cors";
import userRouter from "./routes/usersRoutes.js";
import postRouter from "./routes/postsRoutes.js";
import categoryRouter from "./routes/categoriesRoutes.js";
import notificationRouter from "./routes/notificationsRoutes.js";
import applicationRouter from "./routes/applicationsRoutes.js";
import tokenRouter from "./routes/tokenRoutes.js";
import reportRouter from "./routes/reportsRoutes.js";
import jobRouter from "./routes/jobsRoutes.js";
import storageRoutes from "./routes/storageRoutes.js";
import locationRouter from "./routes/locationsRoutes.js";
import conversationRouter from "./routes/conversationRoutes.js";
import reviewRouter from "./routes/reviewsRoutes.js";
import { setupChatWebSocket } from "./ws/chatWsServer.js";

const app = express();
app.use(cors());
app.use(express.json());

app.use(userRouter);
app.use(postRouter);
app.use(categoryRouter);
app.use(notificationRouter);
app.use(applicationRouter);
app.use(tokenRouter);
app.use(reportRouter);
app.use(jobRouter);
app.use(storageRoutes);
app.use(locationRouter);
app.use(conversationRouter);
app.use(reviewRouter);

const PORT = process.env.PORT || 3001;
const server = createServer(app);
setupChatWebSocket(server);

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
