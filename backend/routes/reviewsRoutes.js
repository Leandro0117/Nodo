import { Router } from "express";
import {
  createRating,
  getUserRatings,
  getRatingByServiceAndUser,
} from "../controllers/reviewController.js";

const reviewRouter = Router();

reviewRouter.post("/api/createRating", createRating);
reviewRouter.get("/api/getUserRatings/:userId", getUserRatings);
reviewRouter.get("/api/getRatingByServiceAndUser/:serviceId/:userId", getRatingByServiceAndUser);

export default reviewRouter;
