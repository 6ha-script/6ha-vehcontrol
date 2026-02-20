/*
    ╔═══════════════════════════════════════════════════════════════╗
    ║                   6HA VEHICLE CONTROL SYSTEM                  ║
    ║                      JavaScript Script                        ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  Developer: 6ha                                               ║
    ║  Discord: https://discord.gg/Zk4TTQrRdh                       ║
    ║  Server: 𝐑𝟔 | 𝐒𝐓𝐎𝐑𝐄                                            ║
    ║  All Rights Reserved © 2026                                   ║
    ╚═══════════════════════════════════════════════════════════════╝
*/

// ══════════════════════════════════════════════════════════════
//                      GLOBAL VARIABLES
// ══════════════════════════════════════════════════════════════

let vehicleData = null;
let currentSeats = {};

// ══════════════════════════════════════════════════════════════
//                    MESSAGE LISTENER
// ══════════════════════════════════════════════════════════════

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'open':
            openUI(data.vehicleData);
            break;
        case 'close':
            closeUI();
            break;
        case 'updateState':
            updateState(data);
            break;
        case 'updateSeats':
            updateSeats(data.seats);
            break;
    }
});

// ══════════════════════════════════════════════════════════════
//                    UI CONTROL FUNCTIONS
// ══════════════════════════════════════════════════════════════

/**
 * فتح واجهة التحكم
 */
function openUI(vehData) {
    vehicleData = vehData;
    const container = document.getElementById('vehcontrol-container');
    container.classList.remove('hidden');
    
    // تحديث رقم اللوحة
    const plate = document.getElementById('vehicle-plate');
    if (plate && vehData.plate) {
        plate.textContent = vehData.plate;
    }
    
    // تحديث حالة الأزرار
    updateButtonStates(vehData);
    
    // تحديث حالة المقاعد
    if (vehData.seats) {
        currentSeats = vehData.seats;
        updateSeats(vehData.seats);
    }
    
    // إخفاء الأقسام غير المتوافقة مع نوع المركبة
    updateVisibility(vehData);
}

/**
 * إغلاق واجهة التحكم
 */
function closeUI() {
    const container = document.getElementById('vehcontrol-container');
    container.classList.add('hidden');
    vehicleData = null;
    currentSeats = {};
}

// ══════════════════════════════════════════════════════════════
//                    BUTTON STATE FUNCTIONS
// ══════════════════════════════════════════════════════════════

/**
 * تحديث حالة جميع الأزرار
 */
function updateButtonStates(data) {
    // المحرك
    const engineBtn = document.querySelector('[data-action="engine"]');
    if (engineBtn) {
        engineBtn.classList.toggle('active', data.engineRunning);
    }
    
    // القفل - تحديث على اللوحة
    const plate = document.getElementById('vehicle-plate');
    if (plate) {
        plate.classList.toggle('locked', data.doorsLocked);
    }
    
    // الأبواب
    if (data.doors) {
        Object.keys(data.doors).forEach(index => {
            const doorBtn = document.querySelector(`[data-action="door"][data-index="${index}"]`);
            if (doorBtn) {
                doorBtn.classList.toggle('active', data.doors[index]);
            }
        });
    }
    
    // النوافذ
    if (data.windows) {
        Object.keys(data.windows).forEach(index => {
            const windowBtn = document.querySelector(`[data-action="window"][data-index="${index}"]`);
            if (windowBtn) {
                windowBtn.classList.toggle('active', data.windows[index]);
            }
        });
    }
    
    // الإضاءة الداخلية
    const lightBtn = document.querySelector('[data-action="interiorLight"]');
    if (lightBtn) {
        lightBtn.classList.toggle('active', data.interiorLight);
    }
    
    // غطاء المحرك
    const bonnetBtn = document.querySelector('[data-action="bonnet"]');
    if (bonnetBtn && data.bonnetOpen !== undefined) {
        bonnetBtn.classList.toggle('active', data.bonnetOpen);
    }
    
    // الصندوق الخلفي
    const trunkBtn = document.querySelector('[data-action="trunk"]');
    if (trunkBtn && data.trunkOpen !== undefined) {
        trunkBtn.classList.toggle('active', data.trunkOpen);
    }
    
    // الإشارات
    updateSignalButtons(data.signalState);
}

/**
 * تحديث أزرار الإشارات
 */
function updateSignalButtons(signalState) {
    const leftBtn = document.querySelector('[data-action="signal"][data-type="left"]');
    const rightBtn = document.querySelector('[data-action="signal"][data-type="right"]');
    const hazardBtn = document.querySelector('[data-action="signal"][data-type="hazard"]');
    
    if (leftBtn) leftBtn.classList.toggle('active', signalState === 'left');
    if (rightBtn) rightBtn.classList.toggle('active', signalState === 'right');
    if (hazardBtn) hazardBtn.classList.toggle('active', signalState === 'hazard');
}

// ══════════════════════════════════════════════════════════════
//                    SEAT MANAGEMENT
// ══════════════════════════════════════════════════════════════

/**
 * تحديث حالة المقاعد
 */
function updateSeats(seats) {
    if (!seats) return;
    
    currentSeats = seats;
    
    Object.keys(seats).forEach(seatIndex => {
        const seatBtn = document.querySelector(`[data-action="seat"][data-index="${seatIndex}"]`);
        if (seatBtn) {
            const seat = seats[seatIndex];
            
            // إزالة جميع الحالات
            seatBtn.classList.remove('current-seat', 'occupied-seat');
            
            // إضافة الحالة المناسبة
            if (seat.isCurrent) {
                seatBtn.classList.add('current-seat');
            } else if (seat.occupied) {
                seatBtn.classList.add('occupied-seat');
            }
        }
    });
}

/**
 * تغيير المقعد
 */
function changeSeat(seatIndex) {
    const seat = currentSeats[seatIndex];
    
    // التحقق من أن المقعد غير مشغول أو هو المقعد الحالي
    if (!seat || !seat.occupied || seat.isCurrent) {
        fetch(`https://${GetParentResourceName()}/changeSeat`, {
            method: 'POST',
            body: JSON.stringify({ seatIndex: parseInt(seatIndex) })
        });
    }
}

// ══════════════════════════════════════════════════════════════
//                    VISIBILITY CONTROL
// ══════════════════════════════════════════════════════════════

/**
 * تحديث الرؤية حسب نوع المركبة
 */
function updateVisibility(data) {
    // إخفاء أزرار معينة حسب نوع المركبة
    const hideDoors = ['motorcycle', 'bicycle', 'plane', 'helicopter'].includes(data.type);
    const hideWindows = ['motorcycle', 'bicycle', 'boat', 'plane'].includes(data.type);
    const hideSeats = ['bicycle'].includes(data.type);
    
    // الأبواب
    document.querySelectorAll('[data-action="door"]').forEach(btn => {
        btn.style.display = hideDoors ? 'none' : 'flex';
    });
    
    // النوافذ
    document.querySelectorAll('[data-action="window"]').forEach(btn => {
        btn.style.display = hideWindows ? 'none' : 'flex';
    });
    
    // المقاعد
    document.querySelectorAll('[data-action="seat"]').forEach(btn => {
        btn.style.display = hideSeats ? 'none' : 'flex';
    });
    
    // تعطيل أزرار معينة
    const bonnetBtn = document.querySelector('[data-action="bonnet"]');
    const trunkBtn = document.querySelector('[data-action="trunk"]');
    
    if (bonnetBtn) {
        bonnetBtn.classList.toggle('disabled', !data.hasBonnet);
    }
    
    if (trunkBtn) {
        trunkBtn.classList.toggle('disabled', !data.hasTrunk);
    }
}

// ══════════════════════════════════════════════════════════════
//                    STATE UPDATE HANDLER
// ══════════════════════════════════════════════════════════════

/**
 * تحديث حالة معينة
 */
function updateState(data) {
    switch(data.state) {
        case 'engine':
            const engineBtn = document.querySelector('[data-action="engine"]');
            if (engineBtn) {
                engineBtn.classList.toggle('active', data.value);
            }
            break;
            
        case 'lock':
            const plate = document.getElementById('vehicle-plate');
            if (plate) {
                plate.classList.toggle('locked', data.value);
            }
            break;
            
        case 'door':
            const doorBtn = document.querySelector(`[data-action="door"][data-index="${data.doorIndex}"]`);
            if (doorBtn) {
                doorBtn.classList.toggle('active', data.value);
            }
            break;
            
        case 'window':
            const windowBtn = document.querySelector(`[data-action="window"][data-index="${data.windowIndex}"]`);
            if (windowBtn) {
                windowBtn.classList.toggle('active', data.value);
            }
            break;
            
        case 'bonnet':
            const bonnetBtn = document.querySelector('[data-action="bonnet"]');
            if (bonnetBtn) {
                bonnetBtn.classList.toggle('active', data.value);
            }
            break;
            
        case 'trunk':
            const trunkBtn = document.querySelector('[data-action="trunk"]');
            if (trunkBtn) {
                trunkBtn.classList.toggle('active', data.value);
            }
            break;
            
        case 'interiorLight':
            const lightBtn = document.querySelector('[data-action="interiorLight"]');
            if (lightBtn) {
                lightBtn.classList.toggle('active', data.value);
            }
            break;
            
        case 'signal':
            updateSignalButtons(data.value);
            break;
    }
}

// ══════════════════════════════════════════════════════════════
//                    BUTTON CLICK HANDLERS
// ══════════════════════════════════════════════════════════════

/**
 * معالجة النقرات على الأزرار
 */
document.addEventListener('click', function(e) {
    const btn = e.target.closest('.control-btn-new');
    if (!btn || btn.classList.contains('disabled')) return;
    
    const action = btn.dataset.action;
    
    // تأثير صوتي خفيف (اختياري)
    playClickSound();
    
    switch(action) {
        case 'engine':
            fetch(`https://${GetParentResourceName()}/toggleEngine`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            break;
            
        case 'door':
            fetch(`https://${GetParentResourceName()}/toggleDoor`, {
                method: 'POST',
                body: JSON.stringify({ doorIndex: parseInt(btn.dataset.index) })
            });
            break;
            
        case 'window':
            fetch(`https://${GetParentResourceName()}/toggleWindow`, {
                method: 'POST',
                body: JSON.stringify({ windowIndex: parseInt(btn.dataset.index) })
            });
            break;
            
        case 'bonnet':
            fetch(`https://${GetParentResourceName()}/toggleBonnet`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            break;
            
        case 'trunk':
            fetch(`https://${GetParentResourceName()}/toggleTrunk`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            break;
            
        case 'interiorLight':
            fetch(`https://${GetParentResourceName()}/toggleInteriorLight`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            break;
            
        case 'seat':
            changeSeat(btn.dataset.index);
            break;
            
        case 'plate':
            fetch(`https://${GetParentResourceName()}/copyPlate`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            break;
            
        case 'signal':
            fetch(`https://${GetParentResourceName()}/toggleSignal`, {
                method: 'POST',
                body: JSON.stringify({ signalType: btn.dataset.type })
            });
            break;
    }
});

// ══════════════════════════════════════════════════════════════
//                    UTILITY FUNCTIONS
// ══════════════════════════════════════════════════════════════

/**
 * تأثير صوتي للنقر (اختياري)
 */
function playClickSound() {
    // يمكن إضافة صوت هنا إذا أردت
}

// ══════════════════════════════════════════════════════════════
//                    KEYBOARD HANDLERS
// ══════════════════════════════════════════════════════════════

/**
 * إغلاق بزر ESC
 */
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            body: JSON.stringify({})
        });
    }
});

/**
 * منع النقر بالزر الأيمن
 */
document.addEventListener('contextmenu', function(e) {
    e.preventDefault();
    return false;
});
