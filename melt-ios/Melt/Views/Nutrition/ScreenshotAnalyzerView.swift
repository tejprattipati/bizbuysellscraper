import SwiftUI
import PhotosUI
import SwiftData

struct ScreenshotAnalyzerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var settings: [UserSettings]
    let log: DailyLog

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var analysisResult: NutritionAnalysis?
    @State private var errorMessage: String?
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Analyze MyFitnessPal Screenshot")
                        .font(.title2.bold())

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No image selected")
                                        .foregroundColor(.secondary)
                                }
                            )
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Screenshot", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                analysisResult = nil
                            }
                        }
                    }

                    if let result = analysisResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Analysis Result")
                                .font(.headline)
                            Group {
                                HStack {
                                    Text("Calories:")
                                    Spacer()
                                    Text("\(result.calories)")
                                        .bold()
                                }
                                HStack {
                                    Text("Protein:")
                                    Spacer()
                                    Text("\(result.protein)g")
                                        .bold()
                                }
                                HStack {
                                    Text("Carbs:")
                                    Spacer()
                                    Text("\(result.carbs)g")
                                        .bold()
                                }
                                HStack {
                                    Text("Fat:")
                                    Spacer()
                                    Text("\(result.fat)g")
                                        .bold()
                                }
                                if result.water > 0 {
                                    HStack {
                                        Text("Water:")
                                        Spacer()
                                        Text(String(format: "%.1fL", result.water))
                                            .bold()
                                    }
                                }
                            }
                            .font(.subheadline)

                            if !result.meals.isEmpty {
                                Text("Detected Meals:")
                                    .font(.subheadline.bold())
                                    .padding(.top, 4)
                                ForEach(result.meals, id: \.name) { meal in
                                    HStack {
                                        Text(meal.name)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(meal.calories) cal / \(meal.protein)g protein")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Button("Apply to Today's Log") {
                                applyAnalysis(result)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    if selectedImage != nil && analysisResult == nil {
                        Button(action: analyzeImage) {
                            if isAnalyzing {
                                HStack {
                                    ProgressView()
                                    Text("Analyzing...")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else {
                                Label("Analyze with Claude AI", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color.purple.opacity(isAnalyzing ? 0.3 : 1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isAnalyzing || (settings.first?.claudeApiKey ?? "").isEmpty)

                        if (settings.first?.claudeApiKey ?? "").isEmpty {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                Text("Add your Claude API key in Settings first.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Screenshot Analyzer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    func analyzeImage() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let apiKey = settings.first?.claudeApiKey, !apiKey.isEmpty else { return }

        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let result = try await ClaudeAPIClient.analyzeNutritionScreenshot(
                    imageData: imageData,
                    apiKey: apiKey
                )
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                    isAnalyzing = false
                }
            }
        }
    }

    func applyAnalysis(_ result: NutritionAnalysis) {
        log.calories = result.calories
        log.proteinGrams = result.protein
        if result.water > 0 { log.waterLiters = result.water }
        log.nutritionScreenshotAnalyzed = true

        // Add each detected meal
        for analyzedMeal in result.meals {
            let meal = MealEntry(mealName: analyzedMeal.name, calories: analyzedMeal.calories, protein: analyzedMeal.protein)
            log.meals.append(meal)
            modelContext.insert(meal)
        }
    }
}

#Preview {
    ScreenshotAnalyzerView(log: DailyLog())
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
