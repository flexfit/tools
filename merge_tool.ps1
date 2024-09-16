# Definiowanie ścieżki katalogu nadrzędnego, branchy źródłowych, docelowego i referencyjnego
$parentDirectory = "C:\Sciezka\Do\Katalogu"  # Zmień na swoją ścieżkę
$sourceBranches = @("branch1", "branch2", "branch3")  # Zmień na listę swoich branchy
$targetBranch = "main"  # Zmień na nazwę swojego docelowego brancha
$referenceBranch = "develop"  # Zmień na nazwę brancha referencyjnego, jeśli branch docelowy nie istnieje

# Pobierz wszystkie podkatalogi
$directories = Get-ChildItem -Path $parentDirectory -Directory

foreach ($dir in $directories) {
    # Przejdź do każdego katalogu
    Set-Location -Path $dir.FullName

    # Sprawdź, czy to repozytorium Git
    if (Test-Path ".git") {
        Write-Output "Przetwarzanie repozytorium w: $($dir.FullName)"
        
        # Sprawdź, czy branch docelowy istnieje
        $branchExists = git branch --list $targetBranch

        if (-not $branchExists) {
            Write-Output "Branch $targetBranch nie istnieje. Tworzenie na podstawie brancha $referenceBranch..."
            git checkout -b $targetBranch origin/$referenceBranch
        } else {
            # Przełącz na branch docelowy
            git checkout $targetBranch

            # Aktualizacja brancha docelowego
            git pull origin $targetBranch
        }

        # Merge branchy w odpowiedniej kolejności z weryfikacją zmian
        foreach ($branch in $sourceBranches) {
            Write-Output "Sprawdzanie zmian do zmergowania dla brancha $branch do $targetBranch..."

            # Pobranie zmian z remote dla brancha źródłowego
            git fetch origin $branch

            # Sprawdzenie, czy istnieją zmiany do zmergowania
            $mergeBase = git merge-base $targetBranch origin/$branch
            $diffOutput = git diff $mergeBase origin/$branch

            if ($diffOutput) {
                Write-Output "Zmiany wykryte. Merging branch $branch into $targetBranch..."
                git merge $branch --no-ff --no-edit
            } else {
                Write-Output "Brak zmian do zmergowania dla brancha $branch."
            }
        }
    } else {
        Write-Output "Pominięto: $($dir.FullName) - nie jest repozytorium Git."
    }

    # Wróć do katalogu nadrzędnego
    Set-Location -Path $parentDirectory
}

Write-Output "Zakończono przetwarzanie wszystkich repozytoriów."
