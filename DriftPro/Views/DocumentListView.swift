import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var documents: [Document] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedCategory: DocumentCategory? = nil
    @State private var showingUpload = false
    @State private var animateList = false
    
    var filteredDocuments: [Document] {
        var filtered = documents
        
        if !searchText.isEmpty {
            filtered = filtered.filter { document in
                document.title.localizedCaseInsensitiveContains(searchText) ||
                document.uploadedByName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient bakgrunn
                AppTheme.mainGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Hero/velkomstseksjon
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentGradient)
                                    .frame(width: 56, height: 56)
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dokumenter & Arkiv")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                Text("Sentralisert dokumenthåndtering")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        // Search and categories
                        searchAndCategoriesSection
                    }
                    
                    // Documents list
                    if isLoading {
                        Spacer()
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.3)
                            
                            Text("Laster dokumenter...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .transition(.opacity.combined(with: .scale))
                        Spacer()
                    } else if filteredDocuments.isEmpty {
                        emptyStateView
                    } else {
                        documentsList
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingUpload = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingUpload) {
            DocumentUploadView()
                .environmentObject(firebaseManager)
        }
        .onAppear {
            loadDocuments()
            withAnimation(.easeInOut(duration: 0.8)) {
                animateList = true
            }
        }
        .refreshable {
            await loadDocumentsAsync()
        }
    }
    
    private var searchAndCategoriesSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Søk i dokumenter...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .accentColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppTheme.glassBackground(cornerRadius: 16))
            .padding(.horizontal, 20)
            .transition(.opacity.combined(with: .move(edge: .top)))
            
            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "Alle",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(DocumentCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    private var documentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredDocuments.enumerated()), id: \.element.id) { index, document in
                    NavigationLink(destination: DocumentDetailView(document: document)) {
                        DocumentCard(document: document)
                            .background(AppTheme.glassBackground(cornerRadius: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    .offset(x: animateList ? 0 : 300)
                    .opacity(animateList ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateList)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient)
                    .frame(width: 120, height: 120)
                    .opacity(0.3)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.white)
            }
            .transition(.opacity.combined(with: .scale))
            
            VStack(spacing: 12) {
                Text(searchText.isEmpty ? "Ingen dokumenter" : "Ingen resultater")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(searchText.isEmpty ? "Last opp ditt første dokument" : "Prøv å endre søkekriteriene")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button(action: { showingUpload = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Last opp dokument")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(AppTheme.accentGradient)
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private func loadDocuments() {
        // Simulate loading data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            documents = [
                Document(title: "Sikkerhetsrutiner 2024", category: .procedures, fileURL: "", fileName: "sikkerhet.pdf", fileSize: 1024000, fileType: "pdf", uploadedBy: "user1", uploadedByName: "Ola Nordmann", companyId: "company1"),
                Document(title: "HMS-rapport Q1", category: .hms, fileURL: "", fileName: "hms_q1.pdf", fileSize: 2048000, fileType: "pdf", uploadedBy: "user2", uploadedByName: "Kari Hansen", companyId: "company1"),
                Document(title: "Kvalitetskontroll protokoll", category: .protocols, fileURL: "", fileName: "kvalitet.pdf", fileSize: 1536000, fileType: "pdf", uploadedBy: "user3", uploadedByName: "Per Olsen", companyId: "company1")
            ]
            isLoading = false
        }
    }
    
    private func loadDocumentsAsync() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            loadDocuments()
        }
    }
}

#Preview {
    DocumentListView()
        .environmentObject(FirebaseManager.shared)
} 