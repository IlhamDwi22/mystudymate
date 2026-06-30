# MyStudyMate 🎓🚀

**MyStudyMate** adalah platform Micro-SaaS produktivitas yang dirancang khusus untuk membantu mahasiswa dalam mengelola aktivitas akademik dan kolaborasi kelompok dalam satu ekosistem digital. Aplikasi ini dikembangkan menggunakan **Flutter** untuk sisi frontend dan **Supabase** sebagai backend andalannya.

---

## 📱 Tech Stack & Arsitektur
Arsitektur ini menggantikan kebutuhan server kompleks mandiri dengan mengandalkan ekosistem Serverless dari Supabase:

*   **Frontend (Mobile)**: [Flutter (Dart)](https://flutter.dev) dengan State Management [Riverpod](https://riverpod.dev) dan Navigation [GoRouter](https://pub.dev/packages/go_router).
*   **Backend & Database**: [Supabase (PostgreSQL)](https://supabase.com) untuk autentikasi, penyimpanan relasional, dan API.
*   **Real-time & Storage**: [Supabase Storage](https://supabase.com/docs/guides/storage) untuk repositori file dan *Postgres Changes* untuk pembaruan papan Kanban waktu nyata (*real-time*).

---

## 🛠️ Fitur Utama (Strict MVP)
Fitur-fitur ini dirancang untuk ringan pada database dan cepat di-deploy:

1.  **Dashboard (Pusat Kendali)**:
    Ringkasan tugas dari *Task Tracker* serta shortcut akses langsung ke fitur lainnya.
2.  **Shared Task Tracker (Papan Kanban)**:
    Papan manajemen tugas kelompok bergaya Kanban dengan status *To-Do, Doing, Done*. Terupdate secara *real-time* menggunakan Supabase Realtime.
3.  **Study-Mate Matchmaking**:
    Pencarian teman belajar berdasarkan program studi, semester, dan mata kuliah (murni berbasis query filter terstruktur tanpa AI).
4.  **Academic Repository**:
    Repositori file awan terpusat (modul praktikum, bank soal, referensi kuliah) yang memanfaatkan Supabase Storage.
5.  **Collaborative Learning Hub**:
    Pembuatan *Digital Flashcards* untuk metode *active recall* serta editor catatan berbasis teks (Markdown) untuk kolaborasi.

---

## 💼 Business Model
*   **Model**: Paid App / One-time Purchase (Sekali beli, rentang harga Rp 15.000 - Rp 25.000).
*   **Alasan**: Menyederhanakan implementasi teknis dengan tidak memerlukan logika kedaluwarsa langganan, pembatasan kuota storage dinamis, atau integrasi payment gateway rumit di dalam aplikasi.

---

## 🚀 Memulai Penggunaan (Getting Started)

### Prasyarat
*   Flutter SDK (v3.35.0 atau terbaru)
*   Dart SDK (v3.9.2 atau terbaru)

### Cara Setup Proyek

1.  **Clone repositori ini**:
    ```bash
    git clone https://github.com/IlhamDwi22/mystudymate.git
    cd mystudymate/mystudymate_app
    ```

2.  **Instalasi dependensi**:
    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Environment Variables**:
    Buat file bernama `.env` di direktori root `mystudymate_app/` dan isi dengan konfigurasi Supabase Anda:
    ```env
    SUPABASE_URL=https://tqrprjzrhqrugzqhemkv.supabase.co
    SUPABASE_ANON_KEY=your_anon_key_here
    ```

4.  **Jalankan aplikasi**:
    ```bash
    flutter run
    ```

5.  **Jalankan pengujian (Unit/Widget Tests)**:
    ```bash
    flutter test
    ```
