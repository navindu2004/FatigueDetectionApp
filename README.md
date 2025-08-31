# Real-Time Driver Fatigue Detection via EEG-ECG Fusion

**Project by: Navindu Nimnal Premaratne (CB011235)**
**A Final Year Project submitted to the School of Computing, University of Staffordshire.**

---

## 1. Project Overview

This repository contains the source code and machine learning artifacts for a real-time, multimodal driver fatigue detection system. The project's core objective is to demonstrate the feasibility of fusing physiological signals (ECG and EEG) to classify a driver's fatigue state and deliver critical alerts via an Apple Watch.

The system is architected as a dual-app prototype:
*   An **iOS companion app** that serves as the central processing hub, running a Core ML model for on-device inference.
*   A **watchOS app** that acts as a data source and an alert interface.

This prototype utilizes high-fidelity simulators for both the ECG and EEG data streams. This approach allows for a complete, end-to-end demonstration of the system's architecture, data pipeline, and real-time feedback loop.

### Key Features
*   **Real-Time Monitoring:** Initiated from the Apple Watch, the system simulates and streams physiological data to the iPhone.
*   **On-Device Machine Learning:** A trained XGBoost model, converted to Core ML, runs every 2 seconds on the iPhone to classify the driver's state as `Awake`, `Drowsy`, or `Fatigued`.
*   **EEG-ECG Fusion:** The system calculates 44 statistical features from both data streams, leveraging a multimodal approach for more robust predictions.
*   **Critical Alert System:** A "Fatigued" prediction on the iPhone immediately triggers a full-screen, haptic alert on the paired Apple Watch.
*   **Data Persistence & Reporting:** All fatigue state changes are saved locally on the iPhone using SwiftData, with a dedicated "Reports" view to analyze historical events.
*   **Pre-Drive Risk Assessment:** A conceptual feature with a working Node.js backend that uses the Google Gemini API to provide a qualitative risk assessment based on user input and their recent fatigue history.

---

## 2. System Architecture

The system is composed of three primary components:

1.  **Offline ML Training Pipeline (`Jupyter Notebook`):**
    *   Written in Python.
    *   Uses a public dataset to train and tune an XGBoost classifier.
    *   Performs feature engineering, model evaluation, and feature importance analysis.
    *   Exports the final, trained model to the Core ML (`.mlmodel`) format.

2.  **iOS/watchOS Application (`Xcode Project`):**
    *   Written natively in Swift & SwiftUI.
    *   The **iOS app** contains the Core ML model and the main `DashboardViewModel`, which orchestrates the entire real-time loop.
    *   The **watchOS app** provides the user interface for session control and receives alerts.
    *   Communication is handled via Apple's `WatchConnectivity` framework.
    *   Data is persisted using `SwiftData`.

3.  **Pre-Drive Backend Service (`Node.js`):**
    *   A lightweight Express.js server.
    *   Exposes a single `/predrive/analyze` endpoint.
    *   Acts as a secure intermediary that receives contextual data from the iOS app and queries the Google Gemini API for a qualitative risk assessment.
    *   Includes a robust fallback mechanism to provide a useful response even if the Gemini API is unavailable.

---

## 3. Getting Started

### Prerequisites
*   **macOS:** macOS Sequoia 15.6 (or newer beta).
*   **Xcode:** Xcode 26.0 (or newer beta).
*   **Apple Devices:** A physical iPhone (iOS 26.0+) and a paired Apple Watch (watchOS 26.0+).
*   **Python:** A Python environment (e.g., Anaconda or `venv`) with the libraries listed in the Jupyter Notebook.
*   **Node.js:** Node.js (v20+) and `npm` for the backend service.
*   **API Key:** A Google Gemini API key.

### Setup & Installation

#### 1. Machine Learning Model
1.  Navigate to the `Machine Learning` directory.
2.  Open the `Fatigue_Detection_Model.ipynb` Jupyter Notebook.
3.  Execute all the cells in order. This will perform the data loading, training, evaluation, and will generate the final `FatigueDetector.mlmodel` file in the project's root directory.

#### 2. Backend Service
1.  Navigate to the `Backend` directory in your terminal.
2.  Create a `.env` file in this directory and add your Gemini API key:
    ```
    GEMINI_API_KEY="YOUR_API_KEY_HERE"
    ```
3.  Install the necessary dependencies:
    ```bash
    npm install
    ```
4.  Start the server:
    ```bash
    node server.js
    ```
5.  The backend will be running on `http://localhost:8787`.

#### 3. iOS & watchOS Application
1.  Open the `FatigueDetector.xcodeproj` file in Xcode.
2.  **Drag and Drop:** Drag the `FatigueDetector.mlmodel` file (generated from the Jupyter Notebook) into the `FatigueDetector` folder within the Xcode Project Navigator. Ensure "Copy items if needed" is checked.
3.  **Set Deployment Targets:**
    *   Select the `FatigueDetector` project in the navigator.
    *   For the `FatigueDetector` (iOS) target, set the "Minimum Deployments" to **iOS 26.0**.
    *   For the `FatigueDetectorWatchApp Watch App` target, set the "Minimum Deployments" to **watchOS 26.0**.
4.  **Configure Signing:** In the "Signing & Capabilities" tab for both the `FatigueDetector` and `FatigueDetectorWatchApp Watch App` targets, select your Apple Developer team.
5.  **Build and Run:**
    *   Select the **`FatigueDetector`** scheme and your physical iPhone as the run destination. Click Run (▶) to install the iOS app.
    *   Then, select the **`FatigueDetectorWatchApp Watch App`** scheme and your physical Apple Watch as the run destination. Click Run (▶) to install the watchOS app.

---

## 4. How to Use and Test the Application

1.  **Connect:** Launch the app on both the iPhone and the Apple Watch. The "Watch Connection" status on the iPhone should turn green and display "Connected".
2.  **Set Simulation Mode (Optional):**
    *   Navigate to the **Settings** tab on the iPhone.
    *   Toggle the **"Simulate Fatigue"** switch ON. This will cause the simulators to generate "fatigued" data patterns for the next session.
3.  **Start Monitoring:**
    *   On the Apple Watch, tap the green **"Start"** button.
    *   The button will turn red, and the status on both the watch and the iPhone will change to "Active".
    *   The ECG and EEG charts on the iPhone dashboard will begin plotting the simulated data in real-time.
4.  **Observe Prediction:**
    *   Every 2 seconds, the iPhone will process the data and make a prediction.
    *   If "Simulate Fatigue" is ON, the "Current Fatigue Level" will change to **Fatigued** within 2-4 seconds, and a critical alert will be sent to the watch.
5.  **View Reports:**
    *   Stop the session from the watch.
    *   Navigate to the **Reports** tab on the iPhone. You will see a new entry in the "Event Log" for each time the fatigue state changed, complete with expandable data snapshots.
