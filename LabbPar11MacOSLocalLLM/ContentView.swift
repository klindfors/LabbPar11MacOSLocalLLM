
//
//  ContentView.swift
//  MacOSLocalLLM
//
//  Created by Ola Knutsson on 2026-06-30.
//  Modified by Kim Lindfors and Miguel Perez dos Santos.
// Prototypen är baserad på Apples webbartikel om Apples Foundation models:
// https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models
//
// AI-deklaration: Koden har granskats och förbättrats med Microsoft Copilot. En del förbättringsförslag och utvecklingsförslag har sparats till dig som student.

import SwiftUI

// Vi måste importera modulen FoundationModels för att kunna använda den lokala språkmodellen
import FoundationModels


struct ContentView: View {
    var body: some View {
        GenerativeView()
    }
}

struct GenerativeView: View {

    @State private var answer: String = ""
    @State private var question: String = ""
    @State private var response: String?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var isError: Bool = false
    @State private var isSuccess: Bool = false
    @State private var selectedChoice: Selection = .summarize
    @State private var dropDownString: String = ""
    @State private var showPopup = false // State to control popup visibility

    // genom @State kommer modellen att komma ihåg konversationen
    @State private var session = LanguageModelSession()

    // Skapa en referens till system language model.
    private let model = SystemLanguageModel.default

    // Preconstructed strings for each selection
    private var selectionStrings: [Selection: String] = [
        .summarize: "Summarize the following text: ",
        .tag: "Generate tags for the following text: ",
        .analyse: "Analyze the following text: ",
        .edit: "Edit the following text: ",
        .tonality: "Change the tonality of the following text to: "
    ]

    // Update dropDownString when selectedChoice changes
    private func updateDropDownString() {
        dropDownString = selectionStrings[selectedChoice] ?? ""
    }

    // funktion för att generera svar
    private func generateAnswer() async {
        showPopup = true // Show popup when starting

        /* ändra här om du vill att modellen inte ska komma ihåg sessionen, dvs. vi kan skapa ny sessioner hela tiden, eller om vi vill byta ämne helt
         det finns också en maxgränsen för kontextfönstret i tokens, alltså */
        //   let session = LanguageModelSession()

        do {
            let response = try await session.respond(to: dropDownString + question)
            answer = response.content
        } catch {
            answer = "Failed to answer the question: \(error.localizedDescription)"
        }

        showPopup = false // Hide popup when done
    }

    //selection enum for cases of editing types
    enum Selection: String, CaseIterable, Identifiable {
        case summarize, tag, analyse, edit, tonality
        var id: Self { self }
    }

    /* Notera att vi behöver 5 olika kontrollfall (case) i vår switch-sats, där vi kan ge olika felmeddelanden om modellens tillgänglighet*/
    var body: some View {
        ZStack {
            switch model.availability {
            case .available:
                // Om modellen är tillgänglig, så visar vi vårt UI för att hantera Input till språkmodellen och output från språkmodellen

                ScrollView {
                    //     Text("The local LLM is available")
                    ScrollView {
                        VStack {
                            /* Design av frågefältet
                             Fundera på om Ask me Anything är en bra rubrik, styrkan i språkmodellen kanske inte ligger i att svara på faktafrågor.
                             Likadant för hjälptexten "Type your question here"*/
                            Text("TextPal")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            

                            Picker("Editing style:", selection: $selectedChoice) {
                                Text("Summarize").tag(Selection.summarize)
                                Text("Analyse text").tag(Selection.analyse)
                                Text("Edit text content").tag(Selection.edit)
                                Text("Change tonality").tag(Selection.tonality)
                                Text("Generate tags").tag(Selection.tag)
                            }
                            .onChange(of: selectedChoice) { _ in
                                updateDropDownString()
                            }

                            TextField("", text: $question, prompt: Text("Enter the text you wish to modify"), axis: .vertical)
                                .lineLimit(3...5)
                                .padding(5)
                                .background {
                                    Color.gray
                                    // Color(.systemGray6)
                                }
                                .font(.system(.title2, design: .rounded))

                            // Knapp för att be om respons på fråga eller uppmaning

                            //Todo: lägg till en boolean för knappen, en timeout för knapptryckningen och en laddningsanimation i fältet.
                            //Lägg till ytterligare kontrollvillkor i outputfältet baserat på knapp-boolean. Eventuell timer knuten till knapp-boolean.
                            Button {
                                Task {
                                    await generateAnswer()
                                }
                            } label: {
                                Text("Generate response")
                                //   .frame(maxWidth: .infinity)
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.extraLarge)
                            //   .padding(.top)
                            .padding()

                            // Design av svarsfältet

                            ScrollView {
                                Text(answer.isEmpty ? "The generated response will appear here." : answer)

                                //todo: här vill vi kunna infoga en laddningsanimation efter att knappen är tryckt
                                //ev utökat kontrollvillkor baserat på answer.isEmpty och button.wasPressed

                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .padding()
                            }
                            .frame(minHeight: 150)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            //  .font(.system(.body, design: .rounded))
                            .font(.system(.title2, design: .rounded))
                            
                            ScrollView{
                                Text("Disclaimer")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                Text("This language model has limited capabilities can make errors. Please make sure that you double check important information.")
                                    .font(.system(.footnote, design: .rounded, weight: .light))
                            }
                            .frame(minHeight: 20)
                            .background(Color.white.opacity(0))
                            .cornerRadius(8)
                            .padding()
                            
                            /* Design av historikfältet

                             Det hjälper användaren att komma ihåg tidigare prompts

                             Kräver en tydlig datastruktur för att bli bra
                             */
                            Rectangle()
                                .frame(height: 1)
                                //  .foregroundColor(Color(.systemGray5))
                                .foregroundColor(Color.gray) //(.systemGray5))
                                .padding(.vertical)
                            Text("Chat History")
                            Text(question)
                            Text(LocalizedStringKey(answer))
                                .font(.system(.body, design: .rounded))

                            //     }
                        }
                    }
                }

            case .unavailable(.deviceNotEligible):
                // Show an alternative UI.
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("No model for you!")
                }
                .padding()

            case .unavailable(.appleIntelligenceNotEnabled):
                // Ask the person to turn on Apple Intelligence.
                Text("Please enable Apple Intelligence in Settings.")

            case .unavailable(.modelNotReady):
                // The model isn't ready because it's downloading or because of other system reasons.
                Text("Model not ready. Try again later.")

            case .unavailable(_):
                // The model is unavailable for an unknown reason.
                Text("Model unavailable") //. Reason: \(other.localizedDescription)  ")
            }

            // Popup for loading state
            if showPopup {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 20) {
                        Text("Generating answer, please wait!")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    .padding()
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
            }
        }
    }

    // Funktion för att testa enskilda prompter och skriva ut till konsolen.
    private func fetchStates() async throws {
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: "List all states in the USA.")
        print(response.content)
    }
}




#Preview {
    ContentView()
}


