//
//  server.mjs
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-08-20.
//

import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { z } from 'zod';
import { GoogleGenAI, Type } from '@google/genai';

const app = express();
app.use(express.json());
app.use(cors({ origin: ['http://localhost:5173', 'http://127.0.0.1:5173'] })); // adjust for your dev/prod origins

const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY });

const InputSchema = z.object({
  sleepHours: z.number().nonnegative(),
  tripDurationHours: z.number().positive(),
  timeOfDay: z.enum(['Morning','Afternoon','Evening','Night']),
  totalDrowsy: z.number().int().optional(),
  totalFatigued: z.number().int().optional(),
  age: z.number().int().optional(),
  heightCm: z.number().int().optional(),
  weightKg: z.number().int().optional()
});

app.post('/predrive/analyze', async (req, res) => {
  const parse = InputSchema.safeParse(req.body);
  if (!parse.success) return res.status(400).json({ error: 'Bad input' });
  const input = parse.data;

  const prompt = `
You are a driver fatigue specialist. Output STRICT JSON with keys:
- riskLevel: "Low"|"Moderate"|"High"
- explanation: string
- recommendations: array of 1-3 strings

Consider:
- Sleep last night: ${input.sleepHours}h
- Planned drive: ${input.tripDurationHours}h at ${input.timeOfDay}
- History: drowsy=${input.totalDrowsy ?? 0}, fatigued=${input.totalFatigued ?? 0}
- Health: age=${input.age ?? 'NA'}, height=${input.heightCm ?? 'NA'}cm, weight=${input.weightKg ?? 'NA'}kg

Be concise and actionable.
`;

  try {
    const responseSchema = {
      type: Type.OBJECT,
      properties: {
        riskLevel: { type: Type.STRING },
        explanation: { type: Type.STRING },
        recommendations: { type: Type.ARRAY, items: { type: Type.STRING } }
      },
      required: ["riskLevel","explanation","recommendations"]
    };

    const out = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema
      }
    });

    const json = JSON.parse(out.text);
    return res.json(json);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Model call failed' });
  }
});

const port = process.env.PORT || 8787;
app.listen(port, () => console.log(`Pre-Drive backend listening on :${port}`));
