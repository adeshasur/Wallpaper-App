// Import Firebase modules
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-app.js";
import { getFirestore, collection, addDoc, getDocs } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-firestore.js";
import { getStorage, ref, uploadBytesResumable, getDownloadURL } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-storage.js";

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDjffxaZJ7vmAlzA-LnN0Vhlh3EBJ4uRqE",
  authDomain: "wallpaper-incc.firebaseapp.com",
  projectId: "wallpaper-incc",
  storageBucket: "wallpaper-incc.appspot.com",
  messagingSenderId: "795698360511",
  appId: "1:795698360511:web:af7e54ac8e2f410a6ad60a",
  measurementId: "G-5LV2TEXN21",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app); // Firestore reference
const storage = getStorage(app); // Storage reference

// Handle adding category
$("#save-category").click(async function () {
  const categoryName = $("#category-name").val();
  const categoryDesc = $("#category-desc").val();
  const categoryThumb = $("#category-thumb")[0].files[0];

  if (!categoryName || !categoryDesc || !categoryThumb) {
    alert("All fields are required!");
    return;
  }

  // Upload thumbnail to Firebase Storage
  const storageRef = ref(storage, `thumbnails/${categoryThumb.name}`);
  const uploadTask = uploadBytesResumable(storageRef, categoryThumb);

  $("#save-category").prop("disabled", true).text("Uploading...");

  uploadTask.on(
    "state_changed",
    (snapshot) => {
      const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      $("#upload-progress").css("width", `${progress}%`).text(`${Math.round(progress)}%`);
    },
    (error) => {
      console.error("Upload failed:", error.message);
      alert("Thumbnail upload failed: " + error.message);
      $("#save-category").prop("disabled", false).text("Save Category");
    },
    async () => {
      // Get the uploaded file's URL
      const thumbnailUrl = await getDownloadURL(uploadTask.snapshot.ref);

      // Save category to Firestore
      try {
        await addDoc(collection(db, "categories"), {
          name: categoryName,
          description: categoryDesc,
          thumbnail: thumbnailUrl,
        });

        alert("Category added successfully!");
        $("#category-form")[0].reset();
        $("#upload-progress").css("width", "0%").text("0%");
        loadCategories(); // Refresh category list
      } catch (error) {
        console.error("Error adding category:", error.message);
        alert("Failed to add category: " + error.message);
      } finally {
        $("#save-category").prop("disabled", false).text("Save Category");
      }
    }
  );
});

// Load categories and display them
async function loadCategories() {
  const categoryList = $("#category-list");
  categoryList.empty(); // Clear the list

  try {
    const querySnapshot = await getDocs(collection(db, "categories"));
    querySnapshot.forEach((doc) => {
      const category = doc.data();
      const listItem = `
        <li class="list-group-item d-flex align-items-center justify-content-between">
          <div>
            <strong>${category.name}</strong>
            <p class="mb-0 text-muted small">${category.description}</p>
          </div>
          <img src="${category.thumbnail}" alt="${category.name}" class="img-thumbnail" style="width: 80px; height: 80px; object-fit: cover;" />
        </li>`;
      categoryList.append(listItem);
    });
  } catch (error) {
    console.error("Error loading categories:", error.message);
  }
}

// Call loadCategories on page load
$(document).ready(function () {
  loadCategories();
});
