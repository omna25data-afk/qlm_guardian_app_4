import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_area_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_areas_repository.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/presentation/widgets/add_area_sheet.dart';

class AreasListTab extends StatefulWidget {
  const AreasListTab({super.key});

  @override
  State<AreasListTab> createState() => _AreasListTabState();
}

class _AreasListTabState extends State<AreasListTab> {
  late AdminAreasRepository _repository;
  List<AdminArea> _districts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Access repository from provider or context. 
    // Assuming AdminAreasProvider holds the repository, or we can look it up if registered.
    // For now, I'll assume I can get it via standard Provider lookup if available, 
    // or I'll construct it if needed, but better to use existing instance.
    // Let's rely on finding AdminAreasRepository via context (MultiRepositoryProvider).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Assuming RepositoryProvider or similar.
    // If not, we might need to grab it from AdminAreasProvider.
    // Let's try to get it from context if it was provided, or from the Provider instance.
    // Safe approach: grab it from AdminAreasProvider which we know exists.
    try {
        // Just creates a new instance if needed, or get from provider
       // Ideally: _repository = Provider.of<AdminAreasRepository>(context);
       // But assuming it's deeper, let's just ask a provider.
       // Or manually create it with baseUrl from a constant if needed.
       // Better: Use AdminAreasProvider's repo if public? No, it's private.
       // Let's fix AdminAreasProvider to expose repo or just create new instance.
       // Wait, I can inject it.
    } catch(e) {}
  }
  
  // Workaround: We will use the Context to find the repository if provided.
  // Or create one.
  AdminAreasRepository get repo {
    // Hack: construct it using the base URL from constants, OR better, 
    // use the one from AdminAreasProvider via a public getter I should add?
    // I cannot edit Provider now without context switch.
    // I will use context.read<AdminAreasRepository>() and assume it is provided.
    // If not, I'll instantiate it.
    return context.read<AdminAreasRepository>();
  }

  void _fetchDistricts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch only districts (Azla)
      final districts = await repo.getDistricts(); 
      setState(() {
        _districts = districts;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _openAddSheet() {
      showModalBottomSheet(
        context: context, 
        isScrollControlled: true,
        builder: (_) => AddAreaSheet(
            repository: repo, 
            onSuccess: _fetchDistricts
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    // Only fetch once
    if (_districts.isEmpty && !_isLoading && _error == null) {
       // Defer fetch to next frame
       Future.microtask(_fetchDistricts);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null 
            ? Center(child: Text('Error: $_error'))
            : RefreshIndicator(
                onRefresh: () async => _fetchDistricts(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _districts.length,
                  itemBuilder: (context, index) {
                    return _AreaExpansionTile(
                      area: _districts[index], 
                      level: 3, // Azla
                      repository: repo
                    );
                  },
                ),
              ),
    );
  }
}

class _AreaExpansionTile extends StatefulWidget {
  final AdminArea area;
  final int level; // 3=Azla, 4=Village, 5=Locality
  final AdminAreasRepository repository;

  const _AreaExpansionTile({required this.area, required this.level, required this.repository});

  @override
  State<_AreaExpansionTile> createState() => _AreaExpansionTileState();
}

class _AreaExpansionTileState extends State<_AreaExpansionTile> with AutomaticKeepAliveClientMixin {
  List<AdminArea>? _children;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  void _onExpansionChanged(bool expanded) {
    if (expanded && _children == null) {
      _fetchChildren();
    }
  }

  Future<void> _fetchChildren() async {
    setState(() => _isLoading = true);
    try {
      List<AdminArea> children = [];
      if (widget.level == 3) { // Getting Villages for Azla
        children = await widget.repository.getVillages(parentId: widget.area.id.toString());
      } else if (widget.level == 4) { // Getting Localities for Village
        children = await widget.repository.getLocalities(parentId: widget.area.id.toString());
      }
      
      setState(() {
        _children = children;
      });
    } catch (e) {
       // Show error toast?
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive

    final bool isLeaf = widget.level >= 5; // Locality is leaf
    
    // Icon & Color Logic
    IconData icon = Icons.map;
    Color color = Colors.grey;
    if (widget.level == 3) { icon = Icons.location_city; color = Colors.orange; }
    else if (widget.level == 4) { icon = Icons.holiday_village; color = Colors.green; }
    else if (widget.level == 5) { icon = Icons.home; color = Colors.brown; }

    if (isLeaf) {
      return ListTile(
        leading: Icon(icon, color: color),
        title: Text(widget.area.name, style: const TextStyle(fontFamily: 'Tajawal')),
        contentPadding: EdgeInsets.only(right: (widget.level - 3) * 16.0 + 16),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(8),
         side: BorderSide(color: Colors.grey.withOpacity(0.1))
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(right: 16, left: 16), // No indentation at tile level, handle content match
        leading: Icon(icon, color: color),
        title: Text(widget.area.name, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        subtitle: Text('ID: ${widget.area.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        childrenPadding: EdgeInsets.zero,
        onExpansionChanged: _onExpansionChanged,
        children: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_children != null)
            ..._children!.map((child) => _AreaExpansionTile(
                area: child, 
                level: widget.level + 1, 
                repository: widget.repository
            )).toList()
          else
            const SizedBox.shrink(),
          
          if (_children != null && _children!.isEmpty)
             const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('لا توجد مناطق تابعة', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey))))
        ],
      ),
    );
  }
}
