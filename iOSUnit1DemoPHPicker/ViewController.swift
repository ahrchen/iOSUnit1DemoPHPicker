//
//  ViewController.swift
//  iOSUnit1DemoPHPicker
//
//  Created by Raymond Chen on 8/7/24.
//

import UIKit
import PhotosUI
import AVKit

class ViewController: UIViewController {

    @IBAction func pickVideoTapped(_ sender: Any) {
        presentVideoPicker()
    }

    @IBAction func playVideo(_ sender: Any) {
        let player = AVPlayer(url: playButtonVideoURL!)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.play()
        }
    }
    @IBOutlet weak var playVideoButton: UIButton!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    private var playButtonVideoURL: URL?

    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playVideoButton.isHidden = true
        progressView.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    
    private func presentVideoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 5
        config.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

}

extension ViewController {
    
    /// Show an alert for the given error
    private func showAlert(for error: Error? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "\(error?.localizedDescription ?? "Please try again...")",
            preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)

        present(alertController, animated: true)
    }
    
    func displayNextVideo() {
        guard let assetIdentifier = selectedAssetIdentifierIterator?.next() else { return }
        currentAssetIdentifier = assetIdentifier
        
        let progress: Progress?
        let itemProvider = selection[assetIdentifier]!.itemProvider
        progress = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            do {
                guard let url = url, error == nil else {
                    throw error ?? NSError(domain: NSFileProviderErrorDomain, code: -1, userInfo: nil)
                }
                let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: localURL)
                try FileManager.default.copyItem(at: url, to: localURL)
                DispatchQueue.main.async {
                    self?.handleCompletion(assetIdentifier: assetIdentifier, object: localURL)
                }
            } catch let catchedError {
                DispatchQueue.main.async {
                    self?.handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: catchedError)
                }
            }
        }
        displayProgress(progress)
    }
    
    func handleCompletion(assetIdentifier: String, object: Any?, error: Error? = nil) {
        guard currentAssetIdentifier == assetIdentifier else { return }
        if let url = object as? URL {
            displayVideoPlayButton(forURL: url)
        }
    }
    
    func displayVideoPlayButton(forURL videoURL: URL?) {
        playButtonVideoURL = videoURL
        playVideoButton.isHidden = videoURL == nil
        progressView.observedProgress = nil
        progressView.isHidden = true
    }
    
    func displayProgress(_ progress: Progress?) {
        playButtonVideoURL = nil
        playVideoButton.isHidden = true
        progressView.observedProgress = progress
        progressView.isHidden = progress == nil
    }
}
