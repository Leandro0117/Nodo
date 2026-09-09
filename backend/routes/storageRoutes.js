// routes/storageRoutes.js
import express from "express";
import { generateUploadUrl } from "../services/storageService.js";

const storageRoutes = express.Router();

storageRoutes.get("/api/generateUploadUrl", async (req, res) => {
  try {
    const { fileName, contentType } = req.query;

    if (!fileName) {
      return res.status(400).json({ error: "Falta el parámetro fileName" });
    }

    const url = await generateUploadUrl(fileName, contentType);
    res.json({ url });
  } catch (error) {
    console.error("Error generando URL firmada:", error);
    res.status(500).json({ error: "Error generando URL firmada" });
  }
});

export default storageRoutes;
