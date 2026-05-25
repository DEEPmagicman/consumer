//
//  ClearHighlightLoadingButton.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 12/05/26.
//

import UIKit
import MHLoadingButton

final class ClearHighlightLoadingButton: LoadingButton {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundColor = .clear
        layer.backgroundColor = UIColor.clear.cgColor
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        backgroundColor = .clear
        layer.backgroundColor = UIColor.clear.cgColor
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        backgroundColor = .clear
        layer.backgroundColor = UIColor.clear.cgColor
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        backgroundColor = .clear
        layer.backgroundColor = UIColor.clear.cgColor
    }
}
