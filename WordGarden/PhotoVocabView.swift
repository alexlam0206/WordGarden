import SwiftUI
import Vision
import CoreML
import MessageUI
import AVFoundation

struct PhotoVocabView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @EnvironmentObject var treeService: TreeService
    @State private var inputImage: UIImage?
    @State private var showingCustomCamera = false

    // For the background removal effect
    @State private var isolatedSubjectImage: UIImage?
    @State private var showOriginalImage = true

    // For image processing
    @State private var isLoading = false
    @State private var identifiedWord: String?
    @State private var errorMessage: String?
    @State private var showingSuccessMessage = false

    // For Mail feedback
    @State private var showingMailView = false
    @State private var showingMailAlert = false
    @State private var mailError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let image = isolatedSubjectImage ?? inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .opacity(showOriginalImage ? (isolatedSubjectImage == nil ? 1 : 0.5) : 1)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 300)

                        Text("Take a photo to identify an object")
                            .foregroundColor(.secondary)
                    }
                }

                if isLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Identifying object...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 80)
                }

                if let word = identifiedWord {
                    VStack(spacing: 16) {
                        Text("Identified Word:")
                            .font(.headline)
                        Text(word.capitalized)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        VStack(spacing: 16) {
                        Button("Add to WordGarden") {
                            addWordToGarden()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .controlSize(.large)

                        Button("Report Incorrect") {
                            reportIncorrectWord()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .frame(maxWidth: .infinity)
                        .controlSize(.large)
                    }
                        .padding(.top, 8)
                        .padding(.horizontal)

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Word added to your garden!")
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                            .transition(.scale.combined(with: .opacity)) // Corrected: .scale.combined(with: .opacity)
                        }
                    }
            }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()

                Button(action: {
                self.showingCustomCamera = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take Photo")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Photo Vocabulary")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCustomCamera) {
            CameraView(capturedImage: self.$inputImage)
        }
        .sheet(isPresented: $showingMailView) {
            if let word = identifiedWord, let image = inputImage {
                MailView(
                    recipient: "alexlamnok@proton.me",
                    subject: "WordGarden - Incorrect Detection Report",
                    body: "The word \"\(word)\" was detected incorrectly. Please see the attached image for details.",
                    attachment: image.jpegData(compressionQuality: 0.8)
                ) { result in
                    // Handle mail compose result if needed
                    print("Mail compose result: \(result)")
                }
            }
        }

        .alert("Could Not Send Email", isPresented: $showingMailAlert, actions: {
            Button("OK") { } // Corrected: Removed unnecessary backslash before quote
        }, message: {
            Text(mailError ?? "An unknown error occurred.")
        })
        .onChange(of: inputImage) { oldImage, newImage in
            guard let image = newImage else { return }
            Task {
                await processImage(image)
            }
        }
        .onAppear {
            if inputImage == nil {
                showingCustomCamera = true
            }
        }
    }

    private func reportIncorrectWord() {
        if MFMailComposeViewController.canSendMail() {
            self.showingMailView = true
        } else {
            self.mailError = "Your device is not configured to send email. Please set up an account in the Mail app."
            self.showingMailAlert = true
        }
    }

    private func addWordToGarden() {
        guard let word = identifiedWord else { return }
        let def = wordStorage.lookupDefinition(for: word) ?? "Add your own definition."
        wordStorage.addWord(text: word, definition: def, example: "")
        treeService.awardStudyProgress()
        wordStorage.addLogEntry("Added word from photo: \(word)")
        withAnimation { showingSuccessMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { self.showingSuccessMessage = false }
        }
    }

    private func processImage(_ image: UIImage) async {
        isLoading = true
        identifiedWord = nil
        errorMessage = nil
        isolatedSubjectImage = nil
        showOriginalImage = true

        // --- Background Removal (Optional) ---
        do {
            let (subjectImage, _) = try await findSubject(in: image)
            self.isolatedSubjectImage = subjectImage
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                self.showOriginalImage = false
            }
        } catch {
            print("Background removal failed: \(error.localizedDescription)")
            // Non-fatal, we can proceed without it
        }

        // --- Local Object Detection ---
        await detect(image: image)

        isLoading = false
    }

    // MARK: - Core ML Object Detection

    private func detect(image: UIImage) async {
        guard let ciImage = CIImage(image: image) else {
            errorMessage = "Failed to convert UIImage to CIImage."
            isLoading = false
            return
        }
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        do {
            let configuration = MLModelConfiguration()
            let model = try VNCoreMLModel(for: MobileNetV2(configuration: configuration).model)
            let request = VNCoreMLRequest(model: model) { request, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Classification failed: \(error.localizedDescription)"
                        self.isLoading = false
                        return
                    }

                    guard let results = request.results as? [VNClassificationObservation] else {
                        self.errorMessage = "Failed to process classification results."
                        self.isLoading = false
                        return
                    }

                    if let topResult = results.first {
                        // The identifier might be in the format "n0123456, word"
                        // We split it to get the more human-readable part.
                        let identifier = topResult.identifier.components(separatedBy: ", ").last ?? topResult.identifier
                        self.identifiedWord = identifier
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = "Could not classify the image."
                    }
                    self.isLoading = false
                }
            }
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFit

            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            try handler.perform([request])

        } catch {
            errorMessage = "Failed to load Core ML model: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Vision Background Removal

    private func findSubject(in image: UIImage) async throws -> (UIImage, CGImage) {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "PhotoVocab", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get CGImage."])
        }
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)

        try handler.perform([request])

        guard let result = request.results?.first else {
            throw NSError(domain: "PhotoVocab", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get Vision result."])
        }

        let pixelBuffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: true)

        // Convert CVPixelBuffer to CGImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let maskedCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw NSError(domain: "PhotoVocab", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage from pixel buffer."])
        }

        let outputImage = UIImage(cgImage: maskedCGImage)
        return (outputImage, maskedCGImage)
    }
}

struct PhotoVocabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { PhotoVocabView() }
            .preferredColorScheme(.light)
    }
}


// MARK: - Mail View

struct MailView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    let attachment: Data?
    let onResult: (Result<MFMailComposeResult, Error>) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        if let attachment = attachment {
            vc.addAttachmentData(attachment, mimeType: "image/jpeg", fileName: "detection.jpg")
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView

        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.onResult(.failure(error))
            } else {
                parent.onResult(.success(result))
            }
            controller.dismiss(animated: true)
        }
    }
}


// MARK: - Custom Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func cameraViewController(_ controller: CameraViewController, didCapture image: UIImage) {
            parent.capturedImage = image
            parent.dismiss()
        }

        func cameraViewControllerDidCancel(_ controller: CameraViewController) {
            parent.dismiss()
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCapture image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! 
    private var captureDevice: AVCaptureDevice? 
    private let photoOutput = AVCapturePhotoOutput()

    private lazy var captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.cornerRadius = 35
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelCapture), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No camera available")
            return
        }
        captureDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    private func setupUI() {
        view.addSubview(captureButton)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancelCapture() {
        delegate?.cameraViewControllerDidCancel(self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from photo data")
            return
        }

        delegate?.cameraViewController(self, didCapture: image)
    }
}

// MARK: - Orientation Helper
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
