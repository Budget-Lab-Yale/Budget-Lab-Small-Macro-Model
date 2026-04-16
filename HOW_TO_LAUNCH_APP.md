# How to Launch the BLSMM App

Quick guide for launching the Budget Lab's Small Macro Model interactive application.

---

## Prerequisites

Make sure you have all required R packages installed:

```r
install.packages(c(
  "shiny", "bslib", "plotly", "DT", "openxlsx",
  "shinyjs", "rhandsontable", "dplyr", "nleqslv"
))
```

---

## Launch Methods

### Method 1: Using app.R (Recommended)

```r
# Navigate to the project directory
setwd("path/to/Small Macro Model")

# Launch the app
source("app.R")
```

### Method 2: Using shiny::runApp()

```r
# From R console
shiny::runApp("path/to/Small Macro Model")
```

### Method 3: RStudio "Run App" Button

1. Open `app.R` in RStudio
2. Click the **"Run App"** button at the top-right of the editor
3. The app will launch in a new window

---

## Expected Behavior

When the app launches successfully, you should see:

- **R Console:** "Listening on http://127.0.0.1:####" (port number varies)
- **Browser:** App opens automatically with the BLSMM interface
- **No errors:** A clean launch with no red error messages

---

## Troubleshooting

### Error: Package not found

**Solution:** Install missing packages:

```r
install.packages("package_name")
```

### Error: Cannot find file

**Solution:** Verify your working directory:

```r
getwd()  # Check current directory
setwd("path/to/Small Macro Model")  # Set to project root
```

### App launches but shows errors

**Solution:** Restart R session and try again:

```r
# In RStudio: Session > Restart R
# Then re-launch app
```

### Very slow performance

**Solution:**
- Close other browser tabs
- Reduce simulation horizon in the app
- Restart R session to clear memory

---

## Testing the App

Once the app launches, test these features:

1. **Input Tables:** Click on any input table and try editing a cell
2. **Run Simulation:** Click the blue "Run Simulation" button
3. **View Charts:** Switch to Dashboard tab to see results
4. **Preset Scenarios:** Try clicking a preset scenario button
5. **Export:** Test CSV and Excel download buttons

All features should work without errors.

---

## System Requirements

- **R:** Version 4.0.0 or higher
- **Browser:** Chrome, Firefox, Safari, or Edge (modern versions)
- **RAM:** 4GB recommended
- **OS:** Windows, macOS, or Linux

---

## Quick Feature Overview

Once launched, you'll see:

- **9 Input Tables:** Year-by-year control over fiscal and monetary policy
- **13 Dashboard Charts:** Real-time visualization of economic impacts
- **8 Deviation Charts:** Scenario vs. baseline comparison
- **Preset Scenarios:** One-click example simulations
- **Export Tools:** Download results to CSV or Excel

---

## Getting Help

**For detailed app usage:** See `docs/README_App.md`

**For model documentation:** See `docs/README_Model.md`

**For project overview:** See `README.md`

**Support:** budget.lab@yale.edu

---

**The app should launch in 5-10 seconds and open in your default web browser. Enjoy exploring BLSMM!**
