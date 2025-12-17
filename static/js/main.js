/**
 * Portfolio - Main JavaScript
 * 
 * Handles all interactive functionality including:
 * - Preloader
 * - Navigation (mobile menu, scroll effects)
 * - Animations (AOS, counters, skill progress)
 * - Project filtering
 * - Testimonial slider
 * - Contact form
 * - Back to top button
 */

'use strict';

// ==================== DOM ELEMENTS ====================
const DOM = {
    preloader: document.getElementById('preloader'),
    header: document.getElementById('header'),
    navMenu: document.getElementById('nav-menu'),
    navToggle: document.getElementById('nav-toggle'),
    navClose: document.getElementById('nav-close'),
    navLinks: document.querySelectorAll('.nav__link'),
    backToTop: document.getElementById('back-to-top'),
    contactForm: document.getElementById('contact-form'),
    formStatus: document.getElementById('form-status'),
    projectsGrid: document.getElementById('projects-grid'),
    filterBtns: document.querySelectorAll('.filter-btn'),
    statNumbers: document.querySelectorAll('.stat-card__number'),
    skillItems: document.querySelectorAll('.skill-item'),
    timelineProgress: document.getElementById('timeline-progress'),
};

// ==================== PRELOADER ====================
const Preloader = {
    init() {
        window.addEventListener('load', () => {
            setTimeout(() => {
                if (DOM.preloader) {
                    DOM.preloader.classList.add('loaded');
                    document.body.style.overflow = '';
                }
            }, 500);
        });
    }
};

// ==================== NAVIGATION ====================
const Navigation = {
    init() {
        // Mobile menu toggle
        if (DOM.navToggle) {
            DOM.navToggle.addEventListener('click', () => this.openMenu());
        }
        
        if (DOM.navClose) {
            DOM.navClose.addEventListener('click', () => this.closeMenu());
        }
        
        // Close menu on link click
        DOM.navLinks.forEach(link => {
            link.addEventListener('click', () => this.closeMenu());
        });
        
        // Close menu on outside click
        document.addEventListener('click', (e) => {
            if (DOM.navMenu && DOM.navMenu.classList.contains('show-menu')) {
                if (!DOM.navMenu.contains(e.target) && !DOM.navToggle.contains(e.target)) {
                    this.closeMenu();
                }
            }
        });
        
        // Header scroll effect
        window.addEventListener('scroll', () => this.handleScroll());
        
        // Active link on scroll
        this.handleActiveLink();
    },
    
    openMenu() {
        if (DOM.navMenu) {
            DOM.navMenu.classList.add('show-menu');
            document.body.style.overflow = 'hidden';
        }
    },
    
    closeMenu() {
        if (DOM.navMenu) {
            DOM.navMenu.classList.remove('show-menu');
            document.body.style.overflow = '';
        }
    },
    
    handleScroll() {
        if (DOM.header) {
            if (window.scrollY > 50) {
                DOM.header.classList.add('scrolled');
            } else {
                DOM.header.classList.remove('scrolled');
            }
        }
    },
    
    handleActiveLink() {
        const sections = document.querySelectorAll('section[id]');
        
        window.addEventListener('scroll', () => {
            const scrollY = window.pageYOffset;
            
            sections.forEach(section => {
                const sectionHeight = section.offsetHeight;
                const sectionTop = section.offsetTop - 100;
                const sectionId = section.getAttribute('id');
                
                if (scrollY > sectionTop && scrollY <= sectionTop + sectionHeight) {
                    DOM.navLinks.forEach(link => {
                        link.classList.remove('active');
                        if (link.getAttribute('href').includes(sectionId)) {
                            link.classList.add('active');
                        }
                    });
                }
            });
        });
    }
};

// ==================== BACK TO TOP ====================
const BackToTop = {
    init() {
        if (!DOM.backToTop) return;
        
        window.addEventListener('scroll', () => {
            if (window.scrollY > 400) {
                DOM.backToTop.classList.add('visible');
            } else {
                DOM.backToTop.classList.remove('visible');
            }
        });
        
        DOM.backToTop.addEventListener('click', (e) => {
            e.preventDefault();
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }
};

// ==================== ANIMATIONS ====================
const Animations = {
    init() {
        // Initialize AOS
        if (typeof AOS !== 'undefined') {
            AOS.init({
                duration: 800,
                easing: 'ease-out',
                once: true,
                offset: 100,
                disable: 'mobile'
            });
        }
        
        // Counter animation
        this.initCounters();
        
        // Skill progress animation
        this.initSkillProgress();
        
        // Timeline progress
        this.initTimelineProgress();
    },
    
    initCounters() {
        const observerOptions = {
            threshold: 0.5,
            rootMargin: '0px'
        };
        
        const counterObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const counter = entry.target;
                    const target = parseInt(counter.dataset.count);
                    this.animateCounter(counter, target);
                    counterObserver.unobserve(counter);
                }
            });
        }, observerOptions);
        
        DOM.statNumbers.forEach(counter => {
            counterObserver.observe(counter);
        });
    },
    
    animateCounter(element, target) {
        const duration = 2000;
        const step = target / (duration / 16);
        let current = 0;
        
        const timer = setInterval(() => {
            current += step;
            if (current >= target) {
                element.textContent = target;
                clearInterval(timer);
            } else {
                element.textContent = Math.floor(current);
            }
        }, 16);
    },
    
    initSkillProgress() {
        const observerOptions = {
            threshold: 0.3,
            rootMargin: '0px'
        };
        
        const skillObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animated');
                    skillObserver.unobserve(entry.target);
                }
            });
        }, observerOptions);
        
        DOM.skillItems.forEach(skill => {
            skillObserver.observe(skill);
        });
    },
    
    initTimelineProgress() {
        if (!DOM.timelineProgress) return;
        
        window.addEventListener('scroll', () => {
            const timeline = document.querySelector('.timeline__content');
            if (!timeline) return;
            
            const timelineRect = timeline.getBoundingClientRect();
            const windowHeight = window.innerHeight;
            
            if (timelineRect.top < windowHeight && timelineRect.bottom > 0) {
                const progress = Math.min(
                    100,
                    Math.max(0, (windowHeight - timelineRect.top) / (timelineRect.height + windowHeight) * 100)
                );
                DOM.timelineProgress.style.height = `${progress}%`;
            }
        });
    }
};

// ==================== PROJECT FILTERING ====================
const ProjectFilter = {
    init() {
        if (!DOM.filterBtns.length || !DOM.projectsGrid) return;
        
        DOM.filterBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                
                // Update active button
                DOM.filterBtns.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                
                // Filter projects
                const filter = btn.dataset.filter;
                this.filterProjects(filter);
            });
        });
    },
    
    filterProjects(filter) {
        const projects = DOM.projectsGrid.querySelectorAll('.project-card');
        
        projects.forEach((project, index) => {
            const category = project.dataset.category || '';
            const tech = (project.dataset.tech || '').toLowerCase();
            
            let shouldShow = false;
            
            if (filter === 'all') {
                shouldShow = true;
            } else {
                shouldShow = category.includes(filter) || tech.includes(filter.toLowerCase());
            }
            
            if (shouldShow) {
                project.style.display = '';
                project.style.animation = `fadeIn 0.5s ease ${index * 0.1}s forwards`;
            } else {
                project.style.display = 'none';
            }
        });
    }
};

// ==================== TESTIMONIAL SLIDER ====================
const TestimonialSlider = {
    init() {
        const swiperContainer = document.querySelector('.testimonials__slider');
        if (!swiperContainer || typeof Swiper === 'undefined') return;
        
        new Swiper('.testimonials__slider', {
            slidesPerView: 1,
            spaceBetween: 30,
            loop: true,
            autoplay: {
                delay: 5000,
                disableOnInteraction: false,
            },
            pagination: {
                el: '.swiper-pagination',
                clickable: true,
            },
            grabCursor: true,
            effect: 'fade',
            fadeEffect: {
                crossFade: true
            }
        });
    }
};

// ==================== CONTACT FORM ====================
const ContactForm = {
    init() {
        if (!DOM.contactForm) return;
        
        DOM.contactForm.addEventListener('submit', (e) => this.handleSubmit(e));
    },
    
    async handleSubmit(e) {
        e.preventDefault();
        
        const form = e.target;
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalBtnText = submitBtn.innerHTML;
        
        // Show loading state
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Invio...';
        
        try {
            const formData = new FormData(form);
            const response = await fetch(form.action, {
                method: 'POST',
                body: formData,
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.showStatus('success', data.message);
                form.reset();
            } else {
                const errorMessage = Object.values(data.errors || {}).flat().join(', ') || 'Errore durante l\'invio.';
                this.showStatus('error', errorMessage);
            }
        } catch (error) {
            this.showStatus('error', 'Si è verificato un errore. Riprova più tardi.');
            console.error('Form submission error:', error);
        } finally {
            submitBtn.disabled = false;
            submitBtn.innerHTML = originalBtnText;
        }
    },
    
    showStatus(type, message) {
        if (!DOM.formStatus) return;
        
        DOM.formStatus.className = `contact-form__status ${type}`;
        DOM.formStatus.textContent = message;
        DOM.formStatus.style.display = 'block';
        
        // Auto hide after 5 seconds
        setTimeout(() => {
            DOM.formStatus.style.display = 'none';
        }, 5000);
    }
};

// ==================== PARTICLES (Hero Background) ====================
const Particles = {
    init() {
        const canvas = document.getElementById('particles');
        if (!canvas) return;
        
        // Simple particle effect using CSS instead of canvas for performance
        const particlesContainer = document.querySelector('.hero__particles');
        if (!particlesContainer) return;
        
        // Create floating particles
        for (let i = 0; i < 20; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.cssText = `
                position: absolute;
                width: ${Math.random() * 4 + 2}px;
                height: ${Math.random() * 4 + 2}px;
                background: rgba(0, 217, 255, ${Math.random() * 0.3 + 0.1});
                border-radius: 50%;
                left: ${Math.random() * 100}%;
                top: ${Math.random() * 100}%;
                animation: float ${Math.random() * 10 + 10}s ease-in-out infinite;
                animation-delay: ${Math.random() * 5}s;
            `;
            particlesContainer.appendChild(particle);
        }
        
        // Add floating animation
        if (!document.getElementById('particle-styles')) {
            const style = document.createElement('style');
            style.id = 'particle-styles';
            style.textContent = `
                @keyframes float {
                    0%, 100% {
                        transform: translateY(0) translateX(0);
                        opacity: 0;
                    }
                    10% {
                        opacity: 1;
                    }
                    50% {
                        transform: translateY(-100px) translateX(50px);
                    }
                    90% {
                        opacity: 1;
                    }
                }
                
                @keyframes fadeIn {
                    from {
                        opacity: 0;
                        transform: translateY(20px);
                    }
                    to {
                        opacity: 1;
                        transform: translateY(0);
                    }
                }
            `;
            document.head.appendChild(style);
        }
    }
};

// ==================== SMOOTH SCROLL ====================
const SmoothScroll = {
    init() {
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', (e) => {
                const href = anchor.getAttribute('href');
                if (href === '#') return;
                
                const target = document.querySelector(href);
                if (target) {
                    e.preventDefault();
                    const headerOffset = 80;
                    const elementPosition = target.getBoundingClientRect().top;
                    const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
                    
                    window.scrollTo({
                        top: offsetPosition,
                        behavior: 'smooth'
                    });
                }
            });
        });
    }
};

// ==================== TYPING EFFECT ====================
const TypingEffect = {
    init() {
        const typingElement = document.querySelector('[data-typing]');
        if (!typingElement) return;
        
        const words = typingElement.dataset.typing.split(',');
        let wordIndex = 0;
        let charIndex = 0;
        let isDeleting = false;
        
        const type = () => {
            const currentWord = words[wordIndex];
            
            if (isDeleting) {
                typingElement.textContent = currentWord.substring(0, charIndex - 1);
                charIndex--;
            } else {
                typingElement.textContent = currentWord.substring(0, charIndex + 1);
                charIndex++;
            }
            
            let typeSpeed = isDeleting ? 50 : 100;
            
            if (!isDeleting && charIndex === currentWord.length) {
                typeSpeed = 2000;
                isDeleting = true;
            } else if (isDeleting && charIndex === 0) {
                isDeleting = false;
                wordIndex = (wordIndex + 1) % words.length;
                typeSpeed = 500;
            }
            
            setTimeout(type, typeSpeed);
        };
        
        type();
    }
};

// ==================== LAZY LOADING ====================
const LazyLoad = {
    init() {
        if ('loading' in HTMLImageElement.prototype) {
            // Native lazy loading supported
            const images = document.querySelectorAll('img[loading="lazy"]');
            images.forEach(img => {
                if (img.dataset.src) {
                    img.src = img.dataset.src;
                }
            });
        } else {
            // Fallback for browsers without native support
            const lazyImages = document.querySelectorAll('img[data-src]');
            
            const imageObserver = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        img.src = img.dataset.src;
                        img.removeAttribute('data-src');
                        imageObserver.unobserve(img);
                    }
                });
            });
            
            lazyImages.forEach(img => imageObserver.observe(img));
        }
    }
};

// ==================== INITIALIZE ====================
document.addEventListener('DOMContentLoaded', () => {
    Preloader.init();
    Navigation.init();
    BackToTop.init();
    Animations.init();
    ProjectFilter.init();
    TestimonialSlider.init();
    ContactForm.init();
    Particles.init();
    SmoothScroll.init();
    TypingEffect.init();
    LazyLoad.init();
    
    console.log('🚀 Portfolio initialized successfully!');
});

// ==================== UTILITY FUNCTIONS ====================
// Debounce function for performance
function debounce(func, wait = 20) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Throttle function for scroll events
function throttle(func, limit = 100) {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}
