//
//  WebViewButtons.swift
//  TDS Video
//
//  Created by Thomas Dye on 06/08/2024.
//

import SwiftUI

struct WebViewButtons: View {
    @State var buttonColour: Color = .purple
    @State var centerButtonColour: Color = .purple
    let Size: CGFloat = 300
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Cursor Navigation")
                    .font(.headline)

                cursorControl

                Divider()

                Text("Scroll Content")
                    .font(.headline)

                scrollControls

                Divider()

                Text("Resize Web Content")
                    .font(.headline)

                resizeControls

                Divider()

                Text("Move Viewport")
                    .font(.headline)

                viewportControls

                Divider()

                saveControls

                Divider()

                extraControls
            }
            .padding()
        }
    }

    // MARK: - Controls

    private var cursorControl: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                controlButton("chevron.up") {
                    CustomWebViewController.shared.moveCursorUp(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorUp(by: 50)
                })
                Spacer()
            }

            HStack {
                controlButton("chevron.left") {
                    CustomWebViewController.shared.moveCursorLeft(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorLeft(by: 50)
                })

                selectButton

                controlButton("chevron.right") {
                    CustomWebViewController.shared.moveCursorRight(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorRight(by: 50)
                })
            }

            HStack {
                Spacer()
                controlButton("chevron.down") {
                    CustomWebViewController.shared.moveCursorDown(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorDown(by: 50)
                })
                Spacer()
            }
        }
    }

    private var scrollControls: some View {
        HStack {
            controlButton("arrow.up.circle") {
                CustomWebViewController.shared.scrollBy(x: 0, y: -100)
            }
            controlButton("arrow.down.circle") {
                CustomWebViewController.shared.scrollBy(x: 0, y: 100)
            }
        }
    }

    private var resizeControls: some View {
        HStack {
            controlButton("plus.magnifyingglass") {
                CustomWebViewController.shared.resizeContent(by: 1.1)
            }
            controlButton("minus.magnifyingglass") {
                CustomWebViewController.shared.resizeContent(by: 0.9)
            }
        }
    }

    private var viewportControls: some View {
        VStack {
            HStack {
                controlButton("chevron.left") {
                    CustomWebViewController.shared.moveHorizontally(by: -10)
                }
                controlButton("chevron.right") {
                    CustomWebViewController.shared.moveHorizontally(by: 10)
                }
            }
            HStack {
                controlButton("chevron.up") {
                    CustomWebViewController.shared.moveVertically(by: -10)
                }
                controlButton("chevron.down") {
                    CustomWebViewController.shared.moveVertically(by: 10)
                }
            }
        }
    }

    private var saveControls: some View {
        Button("💾 Save current settings for domain") {
            CustomWebViewController.shared.saveViewSettings()
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var extraControls: some View {
        HStack {
            controlButton("magnifyingglass") {
                CustomWebViewController.shared.resetZoom()
            }

            controlButton("arrow.counterclockwise.circle") {
                CustomWebViewController.shared.reloadPage()
            }

            Button {
                CustomWebViewController.shared.toggleCursor()
            } label: {
                Image("Cursor")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Size / 7)
                    .foregroundColor(buttonColour)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Components

    private var selectButton: some View {
        Button(action: {
            CustomWebViewController.shared.select()
        }) {
            ZStack {
                Circle()
                    .fill(centerButtonColour)
                    .frame(width: Size / 3, height: Size / 3)
                    .shadow(color: .gray, radius: 10)
                Text("Select")
                    .foregroundColor(buttonColour)
                    .bold()
            }
        }
    }

    private func controlButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: Size / 7)
                .foregroundColor(buttonColour)
        }
        .buttonStyle(.plain)
    }

    private func longPressGesture(action: @escaping () -> Void) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in action() }
    }
}

#Preview {
    WebViewButtons()
}
