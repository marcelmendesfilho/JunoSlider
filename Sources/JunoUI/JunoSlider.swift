import SwiftUI

/// A slider that expands on selection.
public struct JunoSlider: View {
    var sliderValue: CGFloat
    let maxSliderValue: CGFloat
    let baseHeight: CGFloat
    let expandedHeight: CGFloat
    let label: String
    let editingChanged: ((Bool) -> Void)?
    let newSliderValue: ((CGFloat) -> Void)?
    
    @State private var isGestureActive: Bool = false
    @State private var startingSliderValue: CGFloat?
    @State private var sliderWidth = 10.0 // Just an initial value to prevent division by 0
    @State private var isAtTrackExtremity = false
    
    /// Create a slider that expands on selection.
    /// - Parameters:
    ///   - sliderValue: Binding for the current value of the slider
    ///   - maxSliderValue: The highest value the slider can be
    ///   - baseHeight: The slider's height when not expanded
    ///   - expandedHeight: The slider's height when selected (thus expanded)
    ///   - label: A string to describe what the data the slider represents
    ///   - editingChanged: An optional block that is called when the slider updates to sliding and when it stops
    public init(sliderValue: CGFloat, maxSliderValue: CGFloat, baseHeight: CGFloat = 9.0, expandedHeight: CGFloat = 20.0, label: String, editingChanged: ((Bool) -> Void)? = nil, newSliderValue: ((CGFloat) -> Void)? = nil) {
        self.sliderValue = sliderValue
        self.maxSliderValue = maxSliderValue
        self.baseHeight = baseHeight
        self.expandedHeight = expandedHeight
        self.label = label
        self.editingChanged = editingChanged
        self.newSliderValue = newSliderValue
    }
    
    public var body: some View {
        ZStack {
            Capsule()
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                sliderWidth = proxy.size.width
                            }
                    }
                }
                .frame(height: isGestureActive ? expandedHeight : baseHeight)
                .foregroundStyle(
                    Color(white: 0.1, opacity: 0.5)
                        .shadow(.inner(color: .black.opacity(0.3), radius: 3.0, y: 2.0))
                )
                .shadow(color: .white.opacity(0.2), radius: 1, y: 1)
                .overlay(alignment: .leading) {
                    Capsule()
                        .overlay(alignment: .trailing) {
                            Circle()
                                .foregroundStyle(Color.white)
                                .shadow(radius: 1.0)
                                .padding(innerCirclePadding)
                                .opacity(isGestureActive ? 1.0 : 0.0)
                        }
                        .foregroundStyle(Color(white: isGestureActive ? 0.85 : 1.0))
                        .frame(width: calculateProgressWidth(), height: isGestureActive ? expandedHeight : baseHeight)
                }
                .clipShape(.capsule) // Best attempt at fixing a bug https://twitter.com/ChristianSelig/status/1757139789457829902
                .contentShape(.hoverEffect, .capsule)
        }
        .gesture(DragGesture(minimumDistance: 0.0)
            .onChanged { value in
                if startingSliderValue == nil {
                    startingSliderValue = sliderValue
                    isGestureActive = true
                    editingChanged?(true)
                }
                
                let percentagePointsIncreased = value.translation.width / sliderWidth
                let initialPercentage = (startingSliderValue ?? sliderValue) / maxSliderValue
                let newPercentage = min(1.0, max(0.0, initialPercentage + percentagePointsIncreased))
                
                if newPercentage == 0.0 && !isAtTrackExtremity {
                    isAtTrackExtremity = true
                } else if newPercentage == 1.0 && !isAtTrackExtremity {
                    isAtTrackExtremity = true
                } else if newPercentage > 0.0 && newPercentage < 1.0 {
                    isAtTrackExtremity = false
                }
                newSliderValue?(newPercentage * maxSliderValue)
            }
            .onEnded { value in
                // Check if they just tapped somewhere on the bar rather than actually dragging, in which case update the progress to the position they tapped
                if value.translation.width == 0.0 {
                    let newPercentage = value.location.x / sliderWidth
                    newSliderValue?(newPercentage * maxSliderValue)
                }
                
                startingSliderValue = nil
                isGestureActive = false
                editingChanged?(false)
            }
        )
        .hoverEffect(.highlight)
        .animation(.default, value: isGestureActive)
    }
    
    private var innerCirclePadding: CGFloat { expandedHeight * 0.15 }
    
    private func calculateProgressWidth() -> CGFloat {
        let minimumWidth = isGestureActive ? expandedHeight : baseHeight
        let calculatedWidth = (sliderValue / maxSliderValue) * sliderWidth
        
        // Don't let the bar get so small that it disappears
        return max(minimumWidth, calculatedWidth)
    }
}

