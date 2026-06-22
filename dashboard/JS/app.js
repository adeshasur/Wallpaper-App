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
const db = getFirestore(app);
const storage = getStorage(app);

// State cache for wallpapers
let allWallpapers = [];

// Toast Notifications Helper
function showToast(message, type = "success") {
  const container = $("#toast-container");
  const toastId = "toast-" + Date.now();
  const icon = type === "success" ? "bi-check-circle-fill" : "bi-exclamation-triangle-fill";
  const borderColor = type === "success" ? "#10b981" : "#ef4444";
  
  const toastHtml = `
    <div id="${toastId}" class="toast-custom" style="border-left-color: ${borderColor}">
      <i class="bi ${icon} text-${type === 'success' ? 'success' : 'danger'}"></i>
      <div>${message}</div>
    </div>
  `;
  
  container.append(toastHtml);
  
  // Fade out and remove
  setTimeout(() => {
    $(`#${toastId}`).fadeOut(300, function() {
      $(this).remove();
    });
  }, 3500);
}

// -------------------------------------------------------------
// DASHBOARD VIEW LOGIC
// -------------------------------------------------------------

// Fetch count summaries
async function loadDashboardStats() {
  try {
    const categoriesSnapshot = await getDocs(collection(db, "categories"));
    $("#stat-categories-count").text(categoriesSnapshot.size);
    
    const wallpapersSnapshot = await getDocs(collection(db, "wallpapers"));
    $("#stat-wallpapers-count").text(wallpapersSnapshot.size);
  } catch (error) {
    console.error("Error loading stats:", error);
    $("#stat-categories-count").text("Error");
    $("#stat-wallpapers-count").text("Error");
  }
}

// Load a list of recent wallpapers
async function loadRecentWallpapers() {
  const grid = $("#dashboard-wallpaper-grid");
  grid.empty();
  
  try {
    const querySnapshot = await getDocs(collection(db, "wallpapers"));
    if (querySnapshot.empty) {
      grid.html('<div class="text-secondary small py-4 text-center w-100">No wallpapers uploaded yet.</div>');
      return;
    }
    
    const wallpapers = [];
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      data.id = doc.id;
      wallpapers.push(data);
    });
    
    // Sort descending by upload date
    wallpapers.sort((a, b) => {
      const timeA = a.uploadedAt ? a.uploadedAt.toDate() : 0;
      const timeB = b.uploadedAt ? b.uploadedAt.toDate() : 0;
      return timeB - timeA;
    });
    
    // Take the 8 most recent
    const recent = wallpapers.slice(0, 8);
    recent.forEach((wp) => {
      const card = `
        <div class="wallpaper-card">
          <img src="${wp.url}" alt="${wp.title}" class="wallpaper-img" loading="lazy" />
          <div class="wallpaper-overlay">
            <div class="wallpaper-title">${wp.title}</div>
            <div class="wallpaper-cat">${wp.categoryId}</div>
          </div>
        </div>
      `;
      grid.append(card);
    });
  } catch (error) {
    console.error("Error loading recent wallpapers:", error);
    grid.html('<div class="text-danger small py-4 text-center w-100">Failed to load wallpapers.</div>');
  }
}


// -------------------------------------------------------------
// CATEGORIES VIEW LOGIC
// -------------------------------------------------------------

// Save a category
$("#save-category").click(async function () {
  const categoryName = $("#category-name").val().trim();
  const categoryDesc = $("#category-desc").val().trim();
  const categoryThumb = $("#category-thumb")[0].files[0];

  if (!categoryName || !categoryDesc || !categoryThumb) {
    showToast("All fields are required!", "error");
    return;
  }

  // Upload thumbnail image to Firebase Storage
  const storageRef = ref(storage, `thumbnails/${Date.now()}_${categoryThumb.name}`);
  const uploadTask = uploadBytesResumable(storageRef, categoryThumb);

  $("#save-category").prop("disabled", true).html('<span class="spinner-border spinner-border-sm" role="status"></span> Saving...');
  $("#category-progress-container").show();

  uploadTask.on(
    "state_changed",
    (snapshot) => {
      const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      $("#upload-progress").css("width", `${progress}%`);
    },
    (error) => {
      console.error("Upload failed:", error.message);
      showToast("Thumbnail upload failed: " + error.message, "error");
      $("#save-category").prop("disabled", false).html('<i class="bi bi-plus-lg"></i> Save Category');
      $("#category-progress-container").hide();
    },
    async () => {
      try {
        const thumbnailUrl = await getDownloadURL(uploadTask.snapshot.ref);

        // Save category object to Firestore
        await addDoc(collection(db, "categories"), {
          name: categoryName,
          description: categoryDesc,
          thumbnail: thumbnailUrl,
          createdAt: new Date()
        });

        showToast("Category added successfully!");
        $("#category-form")[0].reset();
        $("#category-progress-container").hide();
        $("#upload-progress").css("width", "0%");
        
        loadCategories(); // Refresh list
      } catch (error) {
        console.error("Error adding category:", error.message);
        showToast("Failed to save category: " + error.message, "error");
      } finally {
        $("#save-category").prop("disabled", false).html('<i class="bi bi-plus-lg"></i> Save Category');
      }
    }
  );
});

// Load category listings
async function loadCategories() {
  const categoryList = $("#category-list");
  categoryList.empty();

  try {
    const querySnapshot = await getDocs(collection(db, "categories"));
    if (querySnapshot.empty) {
      categoryList.append('<li class="list-group-item custom-list-item text-secondary text-center small py-3">No custom categories created yet.</li>');
      return;
    }
    
    querySnapshot.forEach((doc) => {
      const category = doc.data();
      const listItem = `
        <li class="list-group-item custom-list-item d-flex align-items-center justify-content-between">
          <div>
            <strong>${category.name}</strong>
            <p class="mb-0 text-muted small mt-1">${category.description}</p>
          </div>
          <img src="${category.thumbnail}" alt="${category.name}" class="img-thumbnail" style="width: 50px; height: 50px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border-color);" />
        </li>`;
      categoryList.append(listItem);
    });
  } catch (error) {
    console.error("Error loading categories:", error.message);
    showToast("Error loading categories: " + error.message, "error");
  }
}


// -------------------------------------------------------------
// WALLPAPERS VIEW LOGIC
// -------------------------------------------------------------

// Populate Category Dropdowns
async function loadCategoriesDropdowns() {
  const uploadSelect = $("#wallpaper-category");
  const filterSelect = $("#wallpaper-filter-category");
  const currentFilter = filterSelect.val() || "all";
  
  uploadSelect.html('<option value="" disabled selected>Select Category...</option>');
  filterSelect.html('<option value="all">All Categories</option>');
  
  try {
    const querySnapshot = await getDocs(collection(db, "categories"));
    
    // Add default static categories map first
    const categoriesMap = new Map();
    categoriesMap.set("nature", "Nature");
    categoriesMap.set("space", "Space");
    categoriesMap.set("cars", "Cars");
    categoriesMap.set("minimal", "Minimal");
    
    // Merge Firestore dynamic categories
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      const id = data.name.toLowerCase().trim();
      categoriesMap.set(id, data.name);
    });
    
    // Append options
    categoriesMap.forEach((name, id) => {
      uploadSelect.append(`<option value="${id}">${name}</option>`);
      filterSelect.append(`<option value="${id}">${name}</option>`);
    });
    
    filterSelect.val(currentFilter);
  } catch (error) {
    console.error("Error loading categories dropdowns:", error);
  }
}

// Upload wallpaper
$("#save-wallpaper").click(async function () {
  const title = $("#wallpaper-title").val().trim();
  const categoryId = $("#wallpaper-category").val();
  const file = $("#wallpaper-file")[0].files[0];

  if (!title || !categoryId || !file) {
    showToast("All fields are required!", "error");
    return;
  }

  // Upload full resolution wallpaper to Firebase Storage
  const storageRef = ref(storage, `wallpapers/${Date.now()}_${file.name}`);
  const uploadTask = uploadBytesResumable(storageRef, file);

  $("#save-wallpaper").prop("disabled", true).html('<span class="spinner-border spinner-border-sm" role="status"></span> Uploading...');
  $("#wallpaper-progress-container").show();

  uploadTask.on(
    "state_changed",
    (snapshot) => {
      const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      $("#wallpaper-progress").css("width", `${progress}%`);
    },
    (error) => {
      console.error("Upload failed:", error.message);
      showToast("Wallpaper upload failed: " + error.message, "error");
      $("#save-wallpaper").prop("disabled", false).html('<i class="bi bi-cloud-arrow-up-fill"></i> Upload Wallpaper');
      $("#wallpaper-progress-container").hide();
    },
    async () => {
      try {
        const downloadUrl = await getDownloadURL(uploadTask.snapshot.ref);

        // Save metadata to Firestore collection
        await addDoc(collection(db, "wallpapers"), {
          title: title,
          url: downloadUrl,
          categoryId: categoryId,
          uploadedAt: new Date()
        });

        showToast("Wallpaper uploaded successfully!");
        $("#wallpaper-form")[0].reset();
        $("#wallpaper-progress-container").hide();
        $("#wallpaper-progress").css("width", "0%");
        
        loadWallpapersPanel(); // Refresh grid view
      } catch (error) {
        console.error("Error saving wallpaper document:", error.message);
        showToast("Failed to save wallpaper metadata: " + error.message, "error");
      } finally {
        $("#save-wallpaper").prop("disabled", false).html('<i class="bi bi-cloud-arrow-up-fill"></i> Upload Wallpaper');
      }
    }
  );
});

// Load wallpapers in Wallpapers panel
async function loadWallpapersPanel() {
  const grid = $("#wallpapers-panel-grid");
  grid.html('<div class="text-secondary small py-4 text-center w-100">Loading wallpapers...</div>');
  
  try {
    const querySnapshot = await getDocs(collection(db, "wallpapers"));
    allWallpapers = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      data.id = doc.id;
      allWallpapers.push(data);
    });
    
    renderFilteredWallpapers();
  } catch (error) {
    console.error("Error loading wallpapers panel:", error);
    grid.html('<div class="text-danger small py-4 text-center w-100">Failed to load wallpapers.</div>');
  }
}

// Render filtered wallpapers
function renderFilteredWallpapers() {
  const grid = $("#wallpapers-panel-grid");
  grid.empty();
  
  const filter = $("#wallpaper-filter-category").val() || "all";
  let filtered = allWallpapers;
  
  if (filter !== "all") {
    filtered = allWallpapers.filter(wp => wp.categoryId === filter);
  }
  
  if (filtered.length === 0) {
    grid.html('<div class="text-secondary small py-4 text-center w-100">No wallpapers found for this category.</div>');
    return;
  }
  
  // Sort descending by upload date
  filtered.sort((a, b) => {
    const timeA = a.uploadedAt ? a.uploadedAt.toDate() : 0;
    const timeB = b.uploadedAt ? b.uploadedAt.toDate() : 0;
    return timeB - timeA;
  });
  
  filtered.forEach((wp) => {
    const card = `
      <div class="wallpaper-card">
        <img src="${wp.url}" alt="${wp.title}" class="wallpaper-img" loading="lazy" />
        <div class="wallpaper-overlay">
          <div class="wallpaper-title">${wp.title}</div>
          <div class="wallpaper-cat">${wp.categoryId}</div>
        </div>
      </div>
    `;
    grid.append(card);
  });
}

// Bind Category filter dropdown change
$("#wallpaper-filter-category").change(function() {
  renderFilteredWallpapers();
});

// -------------------------------------------------------------
// APPLICATION INITIALIZATION (SPA ROUTING)
// -------------------------------------------------------------
$(document).ready(function () {
  // Load initial view
  loadDashboardStats();
  loadRecentWallpapers();
  
  // Navigation Routing Handler
  $('.nav-menu .nav-link').click(function(e) {
    e.preventDefault();
    const target = $(this).data('target');
    
    // Set link active
    $('.nav-menu .nav-link').removeClass('active');
    $(this).addClass('active');
    
    // Transition panels
    $('.panel-section').removeClass('active');
    $(`#panel-${target}`).addClass('active');
    
    // Load targeted content
    if (target === 'dashboard') {
      loadDashboardStats();
      loadRecentWallpapers();
    } else if (target === 'categories') {
      loadCategories();
    } else if (target === 'wallpapers') {
      loadCategoriesDropdowns();
      loadWallpapersPanel();
    }
  });
});
