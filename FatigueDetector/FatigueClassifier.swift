import Foundation
import CoreML
import SwiftUI

final class FatigueClassifier {

    // MARK: - Model + config
    private let model: FatigueModelLEAN
    private let decisionThreshold: Double = 0.50
    private let fatiguedClassIndex = 0

    private let stats: [String: (mean: Double, std: Double)]
    private let featureOrder = [
        "C3_std","ECG_std","C3_max","C3_min","Cz_std","P3_std",
        "P4_std","P3_min","Poz_min","F3_max","ECG_max","HR_mean"
    ]

    // MARK: - Init
    
    init() {
        print("🧪 FatigueClassifier INIT — build marker v3 — bundle:", Bundle.main.bundleIdentifier ?? "nil")
        do {
            let cfg = MLModelConfiguration()
            self.model = try FatigueModelLEAN(configuration: cfg)
        } catch {
            fatalError("FATAL: Failed to load FatigueModelLEAN: \(error)")
        }

        #if os(iOS)
        self.stats = FatigueClassifier.loadStats()
        #else
        self.stats = [:]
        #endif
    }

    // MARK: - Public API (state only)
    func predict(features raw: [String: Double]) -> FatigueState {
        let (state, _) = predictWithProbability(features: raw)
        return state
    }

    // MARK: - Public API (state + probability)
    func predictWithProbability(features raw: [String: Double]) -> (FatigueState, Double) {
        print("🧪 ENTER predictWithProbability — build marker v3")

        // ✅ RE-ENABLE z-scoring using stats loaded from JSON
        func z(_ name: String, _ x: Double) -> Double {
            #if os(iOS)
            if let s = self.stats[name] {
                // (x - mean) / std
                return (x - s.mean) / max(s.std, 1e-6)
            }
            #endif
            return x   // fallback if stats missing
        }



        let C3_std  = z("C3_std",  raw["C3_std"]  ?? 0)
        let ECG_std = z("ECG_std", raw["ECG_std"] ?? 0)
        let C3_max  = z("C3_max",  raw["C3_max"]  ?? 0)
        let C3_min  = z("C3_min",  raw["C3_min"]  ?? 0)
        let Cz_std  = z("Cz_std",  raw["Cz_std"]  ?? 0)
        let P3_std  = z("P3_std",  raw["P3_std"]  ?? 0)
        let P4_std  = z("P4_std",  raw["P4_std"]  ?? 0)
        let P3_min  = z("P3_min",  raw["P3_min"]  ?? 0)
        let Poz_min = z("Poz_min", raw["Poz_min"] ?? 0)
        let F3_max  = z("F3_max",  raw["F3_max"]  ?? 0)
        let ECG_max = z("ECG_max", raw["ECG_max"] ?? 0)
        let HR_mean = z("HR_mean", raw["HR_mean"] ?? 0)

        do {
            let input = try FatigueModelLEANInput(
                C3_std: C3_std, ECG_std: ECG_std, C3_max: C3_max, C3_min: C3_min,
                Cz_std: Cz_std, P3_std: P3_std, P4_std: P4_std, P3_min: P3_min,
                Poz_min: Poz_min, F3_max: F3_max, ECG_max: ECG_max, HR_mean: HR_mean
            )

            let out = try model.prediction(input: input)

            // 👇 NEW: always dump outputs once to verify what's in this target’s model
            FatigueClassifier.dumpAllOutputs(out)

            // Extract p(fatigued) if present
            let p1 = Self.extractP(from: out, classIndex: fatiguedClassIndex)

            // 👇 FIX: read the label robustly (works regardless of property name/case)
            // Read label
            let label = out.FatigueState
            let stateFromLabel: FatigueState =
                (Int(truncatingIfNeeded: label) == fatiguedClassIndex) ? .fatigued : .awake


            // If no probs in this model, synthesize a UI-friendly value (optional)
            print(String(format: "🧪 p(fatigued) for class %d = %.6f", fatiguedClassIndex, p1))

            let finalState: FatigueState
            if p1 >= 0.0 {                       // we successfully read a probability
                finalState = (p1 >= decisionThreshold) ? .fatigued : .awake
            } else {
                finalState = stateFromLabel      // fall back to the label if probs absent
            }

            return (finalState, max(0.0, min(1.0, p1)))

        } catch {
            print("❌ prediction error: \(error)")
            return (.awake, 0.0)
        }
    }

    // MARK: - Helpers

    /// Reads `Fatiguestateprobs` (or `FatigueStateProbs`) from the MLFeatureProvider
    /// and returns p(class=1) regardless of key type (Int/Int64/NSNumber/String).
    private static func extractP(from out: FatigueModelLEANOutput,
                                 classIndex: Int) -> Double {
        let fv = out.featureValue(for: "Fatiguestateprobs")
              ?? out.featureValue(for: "FatigueStateProbs")
        guard let dict = fv?.dictionaryValue else { return -1.0 }

        func toDouble(_ v: Any) -> Double? {
            if let n = v as? NSNumber { return n.doubleValue }
            if let s = v as? String { return Double(s) }
            if let d = v as? Double { return d }
            return nil
        }

        // exact class index (0 or 1)
        let k = classIndex
        if let v = dict[k], let d = toDouble(v) { return d }

        // fallback for string keys "0"/"1"
        if let v = dict["\(k)"], let d = toDouble(v) { return d }

        // last resort: if we only found the other class, invert
        let other = 1 - classIndex
        if let v = dict[other], let d = toDouble(v) { return 1.0 - d }

        return -1.0
    }


    #if os(iOS)
    private static func loadStats() -> [String:(mean: Double, std: Double)] {
        guard let url = Bundle.main.url(forResource: "lean_feature_stats", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String:[String:Double]] else {
            return [:]
        }
        var out: [String:(Double,Double)] = [:]
        for (k,v) in json {
            let mu = v["mean"] ?? 0.0
            let sd = max(v["std"] ?? 1.0, 1e-6)
            out[k] = (mu, sd)
        }
        return out
    }
    #endif

    private static func dumpAllOutputs(_ out: FatigueModelLEANOutput) {
        print("🔎 Output feature names:", out.featureNames)
        for name in out.featureNames {
            if let fv = out.featureValue(for: name) {
                print("🔎 Output[\(name)]:", fv)
            } else {
                print("🔎 Output[\(name)]: <nil>")
            }
        }
    }
}
