/**
 * 🏺 POTTERY CATALOG - WHIMSICAL INTERACTIONS
 *
 * Delightful JavaScript behaviors that celebrate the pottery-making process.
 * All interactions respect user preferences and accessibility guidelines.
 *
 * Features:
 * - Pottery-themed loading states and success celebrations
 * - Stage transition animations and progress tracking
 * - Photo upload magic with clay-shaping progress
 * - Easter eggs: shake detection, konami code, long-press secrets
 * - Contextual pottery puns and encouraging messages
 * - Clay-bounce micro-interactions and touch feedback
 */

class PotteryWhimsyManager {
    constructor() {
        this.isReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        this.konamiSequence = [];
        this.potteryKonami = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'KeyC', 'KeyL', 'KeyA', 'KeyY']; // C-L-A-Y
        this.shakeThreshold = 15;
        this.lastShakeTime = 0;
        this.init();
    }

    init() {
        if (this.isReducedMotion) {
            console.log('🏺 Pottery whimsy running in reduced motion mode');
            return;
        }

        this.setupEventListeners();
        this.initPotteryPuns();
        this.setupStageTransitions();
        this.initPhotoUploadMagic();
        this.setupEasterEggs();

        console.log('🏺 Pottery whimsy system initialized - ready to delight!');
    }

    setupEventListeners() {
        // Clay bounce on interactive elements
        document.addEventListener('click', this.handleClayBounce.bind(this));

        // Ceramic touch feedback
        document.addEventListener('touchstart', this.handleCeramicTouch.bind(this));

        // Pottery wheel button spins
        document.querySelectorAll('.pottery-wheel-button, .fab').forEach(btn => {
            btn.addEventListener('click', this.handleWheelSpin.bind(this));
        });

        // Stage badge hover celebrations
        document.querySelectorAll('.stage-badge').forEach(badge => {
            badge.addEventListener('mouseenter', this.celebrateStage.bind(this));
        });

        // Success celebration triggers
        document.addEventListener('pottery:success', this.handleSuccess.bind(this));
        document.addEventListener('pottery:stageComplete', this.handleStageCompletion.bind(this));
        document.addEventListener('pottery:photoUploaded', this.handlePhotoUploadSuccess.bind(this));
    }

    handleClayBounce(event) {
        const target = event.target.closest('.btn, .pottery-card, .pottery-interactive');
        if (!target || this.isReducedMotion) return;

        // Prevent bounce spam
        if (target.classList.contains('clay-bounce')) return;

        target.classList.add('clay-bounce');
        setTimeout(() => target.classList.remove('clay-bounce'), 600);

        // Add pottery-themed sound effect hint
        this.showQuickMessage(target, this.getRandomPotterySound(), 800);
    }

    handleCeramicTouch(event) {
        const target = event.target.closest('.ceramic-touch');
        if (!target || this.isReducedMotion) return;

        // Create ripple effect
        const rect = target.getBoundingClientRect();
        const x = event.touches[0].clientX - rect.left;
        const y = event.touches[0].clientY - rect.top;

        const ripple = document.createElement('div');
        ripple.style.cssText = `
            position: absolute;
            left: ${x}px;
            top: ${y}px;
            width: 0;
            height: 0;
            background: radial-gradient(circle, var(--clay-primary-light) 0%, transparent 70%);
            border-radius: 50%;
            transform: translate(-50%, -50%);
            pointer-events: none;
            z-index: 1000;
        `;

        target.appendChild(ripple);

        // Animate ripple
        requestAnimationFrame(() => {
            ripple.style.width = '200px';
            ripple.style.height = '200px';
            ripple.style.opacity = '0.3';
            ripple.style.transition = 'all 0.6s ease-out';
        });

        setTimeout(() => ripple.remove(), 600);
    }

    handleWheelSpin(event) {
        const target = event.currentTarget;
        if (this.isReducedMotion) return;

        // Add spinning class
        target.classList.add('pottery-wheel-button');

        // Show encouraging message
        this.showQuickMessage(target, 'Spin that wheel! 🏺', 1200);

        // Remove class after animation
        setTimeout(() => {
            target.classList.remove('pottery-wheel-button');
        }, 800);
    }

    celebrateStage(event) {
        const badge = event.currentTarget;
        if (this.isReducedMotion) return;

        const stage = badge.classList.contains('stage-greenware') ? 'greenware' :
                     badge.classList.contains('stage-bisque') ? 'bisque' :
                     badge.classList.contains('stage-final') ? 'final' : null;

        if (!stage) return;

        // Trigger stage-specific celebration
        const messages = {
            greenware: ['Fresh clay energy! 🌱', 'Shaping dreams into reality! 🤲', 'The journey begins here! ✨'],
            bisque: ['First fire complete! 🔥', 'Bisque brilliance achieved! 🌟', 'Getting stronger by the firing! 💪'],
            final: ['Final firing fantastic! ✨', 'Masterpiece in the making! 🏆', 'Ready to show the world! 🎉']
        };

        const message = messages[stage][Math.floor(Math.random() * messages[stage].length)];
        this.showQuickMessage(badge, message, 1500);
    }

    initPotteryPuns() {
        // Rotate through pottery puns in empty states
        const emptyStates = document.querySelectorAll('.pottery-empty-state');
        emptyStates.forEach(state => {
            this.rotatePotteryMessages(state);
        });

        // Add encouraging messages to loading states
        this.enhanceLoadingStates();
    }

    rotatePotteryMessages(element) {
        const puns = [
            "Don't worry, every potter starts with a lump of clay! 🏺",
            "Time to get your hands muddy and your heart happy! 🤲",
            "Clay today, masterpiece tomorrow! ✨",
            "Your pottery journey is about to get wheely exciting! 🎯",
            "Ready to throw yourself into some clay work? 🌪️",
            "Let's shape something beautiful together! 🎨",
            "Every great potter was once a beginner with dirty hands! 👐",
            "Clay is just earth waiting to become art! 🌍"
        ];

        let currentPun = 0;
        const messageElement = element.querySelector('.pottery-pun-message');

        if (!messageElement) return;

        setInterval(() => {
            if (this.isReducedMotion) return;

            messageElement.textContent = puns[currentPun];
            messageElement.style.animation = 'message-cycle 4s ease-in-out';

            currentPun = (currentPun + 1) % puns.length;

            setTimeout(() => {
                messageElement.style.animation = '';
            }, 4000);
        }, 6000);
    }

    enhanceLoadingStates() {
        const loaders = document.querySelectorAll('.pottery-spinner, .clay-formation-loader, .kiln-loader');
        loaders.forEach(loader => {
            const encouragements = [
                "Shaping your pottery...",
                "Adding that perfect touch...",
                "Crafting something beautiful...",
                "Working the clay magic...",
                "Almost ready to reveal..."
            ];

            // Add rotating encouragement text
            const textElement = document.createElement('div');
            textElement.className = 'loading-encouragement';
            textElement.style.cssText = `
                position: absolute;
                top: 110%;
                left: 50%;
                transform: translateX(-50%);
                font-size: 0.75rem;
                color: var(--on-surface-variant);
                white-space: nowrap;
                text-align: center;
            `;

            loader.style.position = 'relative';
            loader.appendChild(textElement);

            let currentMessage = 0;
            const updateMessage = () => {
                if (this.isReducedMotion) return;
                textElement.textContent = encouragements[currentMessage];
                currentMessage = (currentMessage + 1) % encouragements.length;
            };

            updateMessage();
            setInterval(updateMessage, 2000);
        });
    }

    setupStageTransitions() {
        // Observe stage badge changes and celebrate transitions
        const stageObserver = new MutationObserver((mutations) => {
            mutations.forEach(mutation => {
                if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                    const target = mutation.target;
                    if (target.classList.contains('stage-badge')) {
                        this.handleStageChange(target);
                    }
                }
            });
        });

        document.querySelectorAll('.stage-badge').forEach(badge => {
            stageObserver.observe(badge, { attributes: true });
        });
    }

    handleStageChange(badge) {
        if (this.isReducedMotion) return;

        // Check if this is a new stage completion (empty -> filled)
        if (badge.classList.contains('stage-empty')) return;

        // Trigger graduation celebration
        badge.classList.add('stage-graduation-celebration');

        setTimeout(() => {
            badge.classList.remove('stage-graduation-celebration');
        }, 1500);

        // Show stage-specific success message
        const stageMessages = {
            'stage-greenware': 'Greenware glory! 🌱 Your piece is taking beautiful shape!',
            'stage-bisque': 'Bisque success! 🔥 First firing complete - looking fantastic!',
            'stage-final': 'Final firing fantastic! ✨ Your masterpiece is complete!'
        };

        const stageClass = Array.from(badge.classList).find(cls => cls.startsWith('stage-') && cls !== 'stage-badge');
        if (stageClass && stageMessages[stageClass]) {
            this.showSuccessToast(stageMessages[stageClass]);
        }
    }

    initPhotoUploadMagic() {
        // Enhance file input and drop zones with pottery magic
        document.querySelectorAll('input[type="file"]').forEach(input => {
            input.addEventListener('change', this.handlePhotoSelection.bind(this));
        });

        document.querySelectorAll('.pottery-drop-zone').forEach(zone => {
            this.setupDropZone(zone);
        });

        // Setup upload progress enhancement
        this.setupUploadProgress();
    }

    setupDropZone(zone) {
        zone.addEventListener('dragover', (e) => {
            e.preventDefault();
            zone.classList.add('dragover');
            if (!this.isReducedMotion) {
                this.showQuickMessage(zone, '🏺 Drop your masterpiece here! ✨', 0, false);
            }
        });

        zone.addEventListener('dragleave', (e) => {
            e.preventDefault();
            zone.classList.remove('dragover');
        });

        zone.addEventListener('drop', (e) => {
            e.preventDefault();
            zone.classList.remove('dragover');
            this.handlePhotoDrop(e, zone);
        });
    }

    handlePhotoSelection(event) {
        const files = event.target.files;
        if (files.length === 0) return;

        this.celebratePhotoSelection(files);
    }

    handlePhotoDrop(event, zone) {
        const files = event.dataTransfer.files;
        if (files.length === 0) return;

        this.celebratePhotoSelection(files);
        this.showSuccessToast(`📸 Captured ${files.length} beautiful shot${files.length > 1 ? 's' : ''}!`);
    }

    celebratePhotoSelection(files) {
        if (this.isReducedMotion) return;

        // Create upload celebration animation
        const celebrationMessage = files.length === 1
            ? "Perfect shot! 📸 Your pottery looks amazing!"
            : `${files.length} beautiful shots! 📸✨ Your pottery collection grows!`;

        this.showSuccessToast(celebrationMessage);
    }

    setupUploadProgress() {
        // Enhanced progress bar with clay shaping animation
        document.addEventListener('pottery:uploadStart', (event) => {
            const progressContainer = event.detail.progressContainer;
            if (!progressContainer) return;

            progressContainer.innerHTML = `
                <div class="pottery-upload-progress">
                    <div class="upload-encouragement">Shaping your photo upload... 🏺</div>
                </div>
            `;
        });

        document.addEventListener('pottery:uploadProgress', (event) => {
            const { progress, progressContainer } = event.detail;
            const progressBar = progressContainer.querySelector('.pottery-upload-progress::before');

            if (progressBar && !this.isReducedMotion) {
                progressBar.style.width = `${progress}%`;

                // Update encouragement based on progress
                const encouragement = progressContainer.querySelector('.upload-encouragement');
                if (encouragement) {
                    const messages = {
                        25: "Looking good! 🌱",
                        50: "Halfway to perfection! 🔥",
                        75: "Almost there! ✨",
                        100: "Upload complete! 🎉"
                    };

                    const message = Object.keys(messages).find(threshold => progress >= threshold);
                    if (message && messages[message]) {
                        encouragement.textContent = messages[message];
                    }
                }
            }
        });

        document.addEventListener('pottery:uploadComplete', (event) => {
            const { progressContainer, fileName } = event.detail;

            // Show completion celebration
            progressContainer.classList.add('pottery-upload-complete');
            this.showSuccessToast(`🎉 ${fileName} uploaded successfully! Your pottery looks amazing!`);

            setTimeout(() => {
                progressContainer.classList.remove('pottery-upload-complete');
            }, 2000);
        });
    }

    setupEasterEggs() {
        // Pottery Konami Code (Up, Up, Down, Down, C, L, A, Y)
        document.addEventListener('keydown', this.handleKonamiCode.bind(this));

        // Shake detection for mobile
        if (window.DeviceMotionEvent) {
            window.addEventListener('devicemotion', this.handleShakeDetection.bind(this));
        }

        // Long press on empty states
        document.querySelectorAll('.pottery-empty-state').forEach(state => {
            this.setupLongPressEasterEgg(state);
        });

        // Secret click sequence on pottery cards
        this.setupClickSequenceEasterEgg();
    }

    handleKonamiCode(event) {
        this.konamiSequence.push(event.code);

        // Keep only the last 8 keys
        if (this.konamiSequence.length > 8) {
            this.konamiSequence.shift();
        }

        // Check if sequence matches pottery konami
        if (this.konamiSequence.length === 8 &&
            this.konamiSequence.every((key, index) => key === this.potteryKonami[index])) {

            this.triggerPotteryKonamiEasterEgg();
            this.konamiSequence = []; // Reset sequence
        }
    }

    triggerPotteryKonamiEasterEgg() {
        if (this.isReducedMotion) {
            this.showSuccessToast('🏺 Pottery Master Code Activated! (Effects disabled for accessibility)');
            return;
        }

        document.body.classList.add('pottery-konami-active');

        this.showSuccessToast('🏺 Pottery Master Code Activated! All pottery items are spinning with joy!');

        // Add floating pottery emojis
        this.createFloatingPotteryEmojis();

        setTimeout(() => {
            document.body.classList.remove('pottery-konami-active');
        }, 3000);
    }

    handleShakeDetection(event) {
        const acceleration = event.accelerationIncludingGravity;
        const currentTime = Date.now();

        if (currentTime - this.lastShakeTime < 1000) return; // Prevent spam

        const totalAcceleration = Math.abs(acceleration.x) +
                                 Math.abs(acceleration.y) +
                                 Math.abs(acceleration.z);

        if (totalAcceleration > this.shakeThreshold) {
            this.triggerShakeEasterEgg();
            this.lastShakeTime = currentTime;
        }
    }

    triggerShakeEasterEgg() {
        if (this.isReducedMotion) {
            this.showSuccessToast('📱 Shake detected! (Clay shake effects disabled for accessibility)');
            return;
        }

        document.body.classList.add('shake-detected');

        this.showSuccessToast('📱 Shake detected! Your pottery is dancing with excitement! 🏺💃');

        setTimeout(() => {
            document.body.classList.remove('shake-detected');
        }, 2000);
    }

    setupLongPressEasterEgg(element) {
        let pressTimer;

        const startPress = () => {
            pressTimer = setTimeout(() => {
                if (this.isReducedMotion) {
                    this.showSuccessToast('🤫 Secret potter message! (Visual effects disabled)');
                    return;
                }

                element.classList.add('easter-egg-active');
                setTimeout(() => {
                    element.classList.remove('easter-egg-active');
                }, 3000);
            }, 2000);
        };

        const cancelPress = () => {
            clearTimeout(pressTimer);
        };

        element.addEventListener('mousedown', startPress);
        element.addEventListener('mouseup', cancelPress);
        element.addEventListener('mouseleave', cancelPress);
        element.addEventListener('touchstart', startPress);
        element.addEventListener('touchend', cancelPress);
    }

    setupClickSequenceEasterEgg() {
        let clickSequence = [];
        const requiredSequence = [0, 2, 1, 3]; // Click pattern on cards

        document.querySelectorAll('.pottery-card').forEach((card, index) => {
            card.addEventListener('click', (e) => {
                if (e.target.closest('.pottery-card-menu')) return;

                clickSequence.push(index);

                if (clickSequence.length > 4) {
                    clickSequence.shift();
                }

                if (clickSequence.length === 4 &&
                    clickSequence.every((idx, pos) => idx % 4 === requiredSequence[pos])) {

                    this.triggerClickSequenceEasterEgg();
                    clickSequence = [];
                }
            });
        });
    }

    triggerClickSequenceEasterEgg() {
        this.showSuccessToast('🎯 Potter\'s Eye discovered! You have excellent taste in pottery arrangements! 🏺✨');

        if (!this.isReducedMotion) {
            document.querySelectorAll('.pottery-card').forEach((card, index) => {
                setTimeout(() => {
                    card.style.animation = 'pottery-celebration 1s ease-out';
                    setTimeout(() => {
                        card.style.animation = '';
                    }, 1000);
                }, index * 200);
            });
        }
    }

    // Utility Methods
    showQuickMessage(element, message, duration = 1500, autoHide = true) {
        const messageEl = document.createElement('div');
        messageEl.className = 'pottery-quick-message';
        messageEl.textContent = message;
        messageEl.style.cssText = `
            position: absolute;
            top: -40px;
            left: 50%;
            transform: translateX(-50%);
            background: var(--clay-primary);
            color: var(--surface);
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.7rem;
            white-space: nowrap;
            z-index: 1000;
            animation: stage-reveal 0.3s ease-out;
            pointer-events: none;
        `;

        element.style.position = 'relative';
        element.appendChild(messageEl);

        if (autoHide) {
            setTimeout(() => {
                messageEl.remove();
            }, duration);
        }

        return messageEl;
    }

    showSuccessToast(message, duration = 3000) {
        // Check if toast container exists, create if not
        let toastContainer = document.querySelector('.pottery-toast-container');
        if (!toastContainer) {
            toastContainer = document.createElement('div');
            toastContainer.className = 'pottery-toast-container';
            toastContainer.style.cssText = `
                position: fixed;
                top: 20px;
                left: 50%;
                transform: translateX(-50%);
                z-index: 10000;
                pointer-events: none;
            `;
            document.body.appendChild(toastContainer);
        }

        const toast = document.createElement('div');
        toast.className = 'pottery-toast';
        toast.textContent = message;
        toast.style.cssText = `
            background: var(--greenware);
            color: white;
            padding: 12px 16px;
            border-radius: var(--radius-md);
            margin-bottom: 8px;
            box-shadow: var(--shadow-ceramic);
            animation: ${this.isReducedMotion ? 'none' : 'stage-reveal 0.5s ease-out'};
            max-width: 300px;
            text-align: center;
            font-size: 0.875rem;
            font-weight: 500;
        `;

        toastContainer.appendChild(toast);

        setTimeout(() => {
            if (!this.isReducedMotion) {
                toast.style.animation = 'stage-reveal 0.3s ease-out reverse';
            }
            setTimeout(() => toast.remove(), this.isReducedMotion ? 0 : 300);
        }, duration);
    }

    createFloatingPotteryEmojis() {
        const emojis = ['🏺', '🤲', '🔥', '✨', '🎨', '🌱'];
        const container = document.body;

        for (let i = 0; i < 12; i++) {
            const emoji = document.createElement('div');
            emoji.textContent = emojis[Math.floor(Math.random() * emojis.length)];
            emoji.style.cssText = `
                position: fixed;
                font-size: 24px;
                pointer-events: none;
                z-index: 9999;
                left: ${Math.random() * 100}vw;
                top: 100vh;
                animation: pottery-float-up 3s ease-out forwards;
            `;

            container.appendChild(emoji);

            setTimeout(() => emoji.remove(), 3000);
        }
    }

    getRandomPotterySound() {
        const sounds = ['*squish*', '*plop*', '*splash*', '*whoosh*', '*ping*', '*ceramic clink*'];
        return sounds[Math.floor(Math.random() * sounds.length)];
    }

    // Public API for triggering events
    triggerSuccess(type, data = {}) {
        document.dispatchEvent(new CustomEvent('pottery:success', { detail: { type, ...data } }));
    }

    triggerStageComplete(stage, itemId) {
        document.dispatchEvent(new CustomEvent('pottery:stageComplete', { detail: { stage, itemId } }));
    }

    triggerPhotoUpload(fileName, stage) {
        document.dispatchEvent(new CustomEvent('pottery:photoUploaded', { detail: { fileName, stage } }));
    }
}

// Additional CSS for floating animations
const floatingAnimationCSS = `
@keyframes pottery-float-up {
    0% {
        transform: translateY(0) rotate(0deg);
        opacity: 1;
    }
    100% {
        transform: translateY(-100vh) rotate(360deg);
        opacity: 0;
    }
}
`;

// Inject floating animation CSS
const styleSheet = document.createElement('style');
styleSheet.textContent = floatingAnimationCSS;
document.head.appendChild(styleSheet);

// Initialize pottery whimsy system when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.potteryWhimsy = new PotteryWhimsyManager();
    });
} else {
    window.potteryWhimsy = new PotteryWhimsyManager();
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PotteryWhimsyManager;
}
