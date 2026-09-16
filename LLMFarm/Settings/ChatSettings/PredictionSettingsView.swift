private func infoButton(key: String,
                            title: String,
                            description: String) -> some View {
        Button {
            activeInfo = (activeInfo == key) ? nil : key
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { activeInfo == key },
            set: { if !$0 { activeInfo = nil } }
        ), arrowEdge: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(description)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(idealWidth: 320, maxWidth: 360, maxHeight: 400)
            .presentationCompactAdaptation(.popover)
        }
    }
